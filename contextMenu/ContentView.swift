//
//  ContentView.swift
//  contextMenu
//
//  Created by Luis E. Azmouz on 9/22/25.
//

import Foundation
import SwiftUI
import Photos
import UIKit


struct PhotoGridView: View {
    
    @State private var recentAssets: [PHAsset] = []
    @State private var isAuthorized = false

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        
        NavigationView {
            ZStack {
                if isAuthorized {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(recentAssets, id: \.localIdentifier) { asset in
                                PhotoAssetImageView(asset: asset)
                            }
                        }
                    }
                } else {
                    VStack {
                        Text("Requesting photo library access...")
                            .onAppear {
                                requestPhotoAccess()
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Photos")
        }
        
    }
    
    func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            if status == .authorized || status == .limited {
                DispatchQueue.main.async {
                    self.isAuthorized = true
                    self.fetchLast200Photos()
                }
            }
        }
    }
    
    func fetchLast200Photos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        fetchOptions.fetchLimit = 200
        fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        DispatchQueue.main.async {
            self.recentAssets = assets
        }
    }
}

struct PhotoAssetImageView: View {

    let asset: PHAsset
    let screenWidth: CGFloat = UIScreen.main.bounds.width
    
    @State private var fullSizePreviewImage: UIImage? = nil
    @State private var thumbnailImage: UIImage? = nil
    @State private var requestID: PHImageRequestID?

    // A single, shared caching manager for all cells:
    static let cachingManager = PHCachingImageManager()
    
    var body: some View {
        
        Group {
            
            if let image = thumbnailImage {
                
                Button{
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.25)
                }label: {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width:  screenWidth * 0.3, height: screenWidth * 0.3)
                      
                }
                .contextMenu(menuItems: {
                    Text(asset.creationDate?.description ?? "")
                        .onAppear{
                            if fullSizePreviewImage == nil{
                                getFullSizeImage()
                            }
                        }
                        .onDisappear {
                            cancelRequest()
                            DispatchQueue.main.async{
                                fullSizePreviewImage = nil
                            }
                        }
                }, preview: {
                    
                    Group(){
                        if let image = fullSizePreviewImage{
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        }else{
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                  
                    
                })
                
            } else {
                Color.gray.opacity(0.2)
                    .overlay(
                        ProgressView()
                    )
            }
            
        }
        .onAppear {
            if thumbnailImage == nil {
                loadThumbImage()
            }

        }
      
    
    }
    
    private func cancelRequest() {
        if let id = requestID {
            Self.cachingManager.cancelImageRequest(id)
            print("cancelling" + id.description)
        }
        
    }
    
    private func getFullSizeImage() {
        
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.resizeMode = .none

        let targetSize = CGSize(width: 1000, height: 1000)

        self.requestID = Self.cachingManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { img, _ in
            DispatchQueue.main.async {
                print("Full-size image fetched? \(img != nil)")
                fullSizePreviewImage = img
            }
        }
        
    }
    
    private func loadThumbImage() {
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        
        Self.cachingManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { result, info in
            if let result = result {
                self.thumbnailImage = result
            } else {
                print("Could not load image for asset: \(asset.localIdentifier)")
            }
        }
        
    }
    
}





