# XBImageFilters

XBImageFilters allows you to obtain filtered versions of any image or from the camera in realtime. It uses OpenGL ES 2 to filter the images through fragment shaders you write yourself so you can filter your images in whatever way you want and it is super fast.

![Luminance](http://xissburg.com/images/ImageFilterSingle.png)

In this screenshot of the sample we have on the top half of the screen a regular UIImageView with contentMode set to UIViewContentModeTop, and on the bottom half a XBFilteredImageView with the same image with contentMode set to UIViewContentModeBottom and a filter [a GLSL fragment shader] that outputs the luminance of the pixel color.

![Gaussian Blur](http://xissburg.com/images/ImageFilterMultiPass.png)

Convoluted Gaussian Blur, an example of a multi-pass filter. It uses two fragment shaders for this, VGaussianBlur.glsl, HGaussianBlur.glsl. First, it uses VGaussianBlur to perform a vertical blur and the resulting image is stored in an OpenGL texture, then it uses HGaussianBlur to apply a horizontal blur in the previous texture that it rendered into. As a result we have a proper Gaussian Blur with a radial kernel.

![Camera Filter](http://xissburg.com/images/CameraFilter.png)

Real time camera filter. It also allows you to take pictures in `UIImage`s with the filter applied with the `-[XBFilteredView takeScreenshot]` method.

## Architecture

XBImageFilters uses OpenGL to draw something applying any custom OpenGL ES 2 fragment shader on it, which gives a lot of freedom on what can be done since we have to write the algorithm that computes the final color for each pixel. It simply builds a rectangle (with 2 triangles) and applies the image or data supplied as a texture on this rectangle. Then, it sets some custom transforms on this rectangle that you can provide, sets the custom fragment shader and draws the result to the screen. Whenever you want to you can change some parameter (like the radius of the blur in a blur filter) and redraw.

In the core of XBImageFilters in the XBFilteredView, a subclass of UIView that encapsulates all of the OpenGL stuff in it. It creates the GLKView (yes, this project uses GLKit), setups textures, additional framebuffers and textures for multi-pass filters that perform some render to texture steps, the single and simple vertex buffer, the transforms for the content, the shaders, the drawing code, and more. This class is not intended to be used directly. It might be conceptually considered an abstract class. If you think of something else that can be filtered, you can implement a subclass of XBFilteredView and provide content through its 'protected methods' `_setTextureData:width:height:` and `_updateTextureWithData:`. The concrete filter classes at this moment are XBFilteredImageView and XBFilteredCameraView.

The XBFilteredImageView is a subclass of XBImageFilters that has an `image` property. You can set an image to it and then set a filter shader with the method `setFilterFragmentShaderFromFile:error:` or multiple filters with `setFilterFragmentShadersFromFiles:error:`, then the view will be automatically redrawn. 

The XBFilteredCameraView is a subclass of XBImageFilters that allows you to filter the input image of a camera in real-time. You can instantiate it, set some filters and call `startCapturing` to start the real-time rendering. You can also take a photo as an UIImage with the method `takeScreenshot`.

To write your own shaders you should have a good grasp of the OpenGL architecture and especially the GLSL language and how shaders work. In short, a fragment shader is a piece of code that runs for each pixel in the GPU and returns the final color for that pixel. You can have access to the value of some variables you define your self in the shader. You can declare a `uniform` variable (constant for all pixels) and provide a value for it from your code that runs on the CPU and then use that value to compute the final color of the pixel. Using uniforms you can control things in your filter like blur radius, montion blur direction, etc.

XBImageFilters use the class GLKProgram to store shader information. These programs are available in the `programs` NSArray property of the XBFilteredView. The `setValue:forUniformNamed:` method allows you to change the value of a uniform in your shader. You need to know its name (the variable name in the shader) and you have to provide the value in a buffer of the same size as the uniform type size. 

If you have multiple textures in your shader (note that OpenGL ES 2 only supports 2 simulataneous textures and XBImageFilters already takes one, that by default its sampler must have the `s_texture` name), you can load that texture from file using GLKTextureLoaderand and call the method `bindSamplerNamed:toTexture:unit:`, where the name must be the sampler variable name, the texture must be the `name` property of the GLKTextureInfo and unit must be `GL_TEXTURE1` since the 0 unit is used by XBFilteredView.

## How to use

### Image Filtering

Create a XBFilteredImageView instance and assign its image and set one or more filters and add it as subview. Have a look in the ImageViewController.m for details.

```objective-c
XBFilteredImageView *filteredImageView = [[XBFilteredImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height];
filteredImageView.image = [UIImage imageNamed:@"raccoons"];
NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"SomeFilterFragmentShader" ofType:@"glsl"];
[filteredImageView setFilterFragmentShaderFromFile:shaderPath error:NULL];
[self.view addSubview:filteredImageView];
```

### Real-time Camera Filtering

Create a XBFilteredCameraView instance, set its filters, add as subview and call `startCapturing`. See more details in CameraViewController.m.

```objective-c
XBFilteredCameraView *filteredCameraView = [[XBFilteredCameraView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height];
NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"SomeFilterFragmentShader" ofType:@"glsl"];
[filteredCameraView setFilterFragmentShaderFromFile:shaderPath error:NULL];
[self.view addSubview:filteredCameraView];
[filteredCameraView startCapturing];
```

While capturing you can grab a photo through the `takeScreenshot`, which returns an UIImage ready to use.

## Project Status

This project is in an early stage of development so not all features advertised are totally functional and performant yet.

## License

This project is under the MIT license (details in COPYRIGHT.txt). Do whatever you want with it and contributions of any form are very welcome.
