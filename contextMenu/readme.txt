When using a contextMenu in SwiftUI to show a preview of a PHAsset’s full-size image via PHCachingImageManager.requestImage(), memory usage increases with each image preview interaction. The memory is not released, leading to eventual app crash due to memory exhaustion.

The thumbnail loads and behaves as expected, but each call to fetch the full-size image (1000x1000) for the contextMenu preview does not release memory, even after cancelImageRequest() is called and fullSizePreviewImage is set to nil.

The issue seems to stem from the contextMenu lifecycle behavior, it triggers .onAppear unexpectedly, and the full-size image is repeatedly fetched without releasing the previously loaded images.

The question is, where do I request to the get the full-size image to show it in the context menu preview?


STEPS TO REPRODUCE
1/ Create a SwiftUI LazyVGrid displaying many PHAsset thumbnails using PHCachingImageManager.
2/ Add a .contextMenu to each thumbnail button with: .onAppear that triggers requestImage() for a high-resolution preview. .onDisappear that calls cancelImageRequest() and sets the image @State to nil.
3/ Tap on several image previews
4/ Monitor memory usage as it increases and eventually crashes
