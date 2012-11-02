# XBImageFilters

XBImageFilters allows you to obtain filtered versions of any image or from the camera in realtime. It uses OpenGL ES 2 to filter the images through fragment shaders you write yourself so you can filter your images in whatever way you want and it is super fast.

![Luminance](http://xissburg.com/images/ImageFilterSingle.png)

In this screenshot of the sample we have on the top half of the screen a regular UIImageView with contentMode set to UIViewContentModeTop, and on the bottom half a XBFilteredImageView with the same image with contentMode set to UIViewContentModeBottom and a filter [a GLSL fragment shader] that outputs the luminance of the pixel color.

![Gaussian Blur](http://xissburg.com/images/ImageFilterMultiPass.png)

Convoluted Gaussian Blur, an example of a multi-pass filter. It uses two fragment shaders for this, VGaussianBlur.glsl, HGaussianBlur.glsl. First, it uses VGaussianBlur to perform a vertical blur and the resulting image is stored in an OpenGL texture, then it uses HGaussianBlur to apply a horizontal blur in the previous texture that it rendered into. As a result we have a proper Gaussian Blur with a radial kernel.

![Camera Filter](http://xissburg.com/images/CameraFilter.png)

Real time camera filter. It also allows you to take pictures in `UIImage`s with the filter applied with the `-[XBFilteredView takeScreenshot]` method.

![High Resolution Photo](http://xissburg.com/images/IMG_0328.JPG)

You can also take high resolution photos with filters. Isn't that awesome?

## How to use

### Frameworks

A few frameworks must be added to your project in order to link XBImageFilters successfully:

* QuartzCore
* CoreMedia
* CoreVideo
* OpenGLES
* AVFoundation
* GLKit

### Image Filtering

The XBFilteredImageView is a view backed by an OpenGL layer which displays an image after applying a custom shader on it. To use it, create a XBFilteredImageView instance and set its image and one or more filters and add it as subview. Have a look in the ImageViewController.m to see a complete example.

```objective-c
XBFilteredImageView *filteredImageView = [[XBFilteredImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height];
filteredImageView.image = [UIImage imageNamed:@"raccoons"];
NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"SomeFilterFragmentShader" ofType:@"glsl"];
NSError *error = nil;
if (![filteredImageView setFilterFragmentShaderFromFile:shaderPath error:&error]) {
    NSLog(@"%@", [error localizedDescription]);
}
[self.view addSubview:filteredImageView];
```

Of course you can also create a XBFilteredImageView in Interface Builder. Just create an UIView, set its class to XBFilteredImageView and connect to an IBOutlet. Then, in a view controller you can set up its shaders in `viewDidLoad`.

### Real-time Camera Filtering

The XBFilteredCameraView is a view backed by an OpenGL layer which displays the image from one of the cameras after applying a custom shader on it in real-time. To use it, create a XBFilteredCameraView instance, set its filters, add as subview and call `-[XBFilteredCameraView startCapturing]`. You can find a complete example in CameraViewController.m.

```objective-c
XBFilteredCameraView *filteredCameraView = [[XBFilteredCameraView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height];
NSString *shaderPath = [[NSBundle mainBundle] pathForResource:@"SomeFilterFragmentShader" ofType:@"glsl"];
NSError *error = nil;
if (![filteredCameraView setFilterFragmentShaderFromFile:shaderPath error:&error]) {
    NSLog(@"%@", [error localizedDescription]);
}
[self.view addSubview:filteredCameraView];
[filteredCameraView startCapturing];
```

While capturing you can grab a photo through the `takeAPhotoWithCompletion:`, which gives you a high resolution UIImage with the filter applied in the completion block. You can also create XBFilteredCameraViews in Interface Builder as well.


### Writing Filters

To write your own shaders you should have a good grasp of the OpenGL architecture and especially the GLSL language and how shaders work. In short, a fragment shader is a piece of code that runs in the GPU for each pixel, and returns the final color for that pixel. You can have access to the value of some variables you define yourself in the shader. You can declare a `uniform` variable (constant for all pixels) and provide a value for it from your code that runs on the CPU and then use that value to compute the final color of the pixel. Using uniforms you can control things in your filter like blur radius, montion blur direction, etc.

Being a bit pedantic, the fragment shader is not actually ran for each pixel. There might be more than a single _sampling point_ in each pixel on the screen, and the fragment shader is ran for each of these sampling points. So, if we have 4 sampling points, the fragment shader will be run 4 times per pixel. But in what situation would a pixel have more than one sampling point? When we're using _multisampling anti-aliasing_. In order to keep the edges smooth, multisampling samples several points in different locations inside each pixel and averages the sampled values to obtain the final pixel color, in a step that is usually known as _resolving the multisample framebuffer_.

XBImageFilters use the class GLKProgram to store shader information. These programs are available in the `programs` NSArray property of the XBFilteredView (and its subclasses, of course). The `setValue:forUniformNamed:` method allows you to change the value of a uniform in your shader. You need to know its name (the variable name in the shader) and you have to provide the value in a buffer of the same size as the uniform type size (the data is copied and the memory is managed internally).

The simplest possible fragment shader is the one which outputs the original color of the input image:

```glsl
precision mediump float;

uniform sampler2D s_texture;

varying vec2 v_texCoord;

void main()
{
    gl_FragColor = texture2D(s_texture, v_texCoord);
}
```

The statement `precision mediump float` is required and it specifies the precision of the floating point values. 

The `uniform sampler2D s_texture` is used to sample colors from a texture in a specific location (texture coordinate). It is either the image in the XBFilteredImageView or the image of the camera in the XBFilteredCameraView. Your main texture sampler __must__ be named `s_texture`.

The `varying vec2 v_texCoord` is the texture coordinate at the current fragment. It is automatically interpolated throughout the triangle which is being rendered/rasterized.

`void main()` starts the definition of the main function that will be run in the GPU for each fragment. It's here that we do all the crazy math necessary. In the end of it we have to assign a value to the `gl_FragColor` variable, which determines the final color for the current fragment. In this case, we're just assigning the color of the main texture at the texture coordinate v_texCoord, which will map the original image straight on the screen/view. The `texture2D` function performs the texture sampling. It takes the sampler in the first argument, which determines how the texture should be sampled (minification filter, magnification filter, wrapping modes, etc), and the second argument is the texture coordinate in normalized space (it goes from 0 to 1 in both dimensions, where, horizontally, 0 is the left and 1 is the right of the texture, and vertically, 0 is the bottom and 1 is the top of the texture).

The principles are basically the same for any other filter. Just figure out the math required to convert your colors and write it. Of course there are several tricks into implementing filters that are worth learning such as _look up tables_, multitexturing, and it's also important to learn more about some GLSL built-in functions such as _mix_, _smooth_, _clamp_, and many others. Look into the [GLSL ES Specification](http://www.khronos.org/registry/gles/specs/2.0/GLSL_ES_Specification_1.0.17.pdf) to learn more, and also look into the sample filters, of course.

## Internals

XBImageFilters uses OpenGL to draw textured planes applying any custom OpenGL ES 2 fragment shader on it, which gives a lot of freedom on what can be done since we have to write the algorithm that computes the final color for each pixel. It simply builds a rectangle (with 2 triangles) and applies the image or data supplied as a texture on this rectangle. Then, it sets some custom transforms on this rectangle that you can provide, sets the custom fragment shader and draws the result to the screen. Whenever you want to you can change some parameter/uniform (like the radius of the blur in a blur filter) and redraw.

In the core of XBImageFilters in the XBFilteredView, a subclass of UIView that encapsulates all of the OpenGL stuff in it. It creates the GLKView (yes, this project uses GLKit), setups textures, additional framebuffers and textures for multi-pass filters that perform some render to texture (RTT) steps, the single and simple vertex buffer, the transforms for the content, the shaders, the drawing code, and more. This class is not intended to be used directly. It might be conceptually considered an abstract class. If you think of something else that can be filtered, you can implement a subclass of XBFilteredView and provide content through its _protected methods_ `_setTextureData:width:height:` and `_updateTextureWithData:`. The concrete filter classes at this moment are XBFilteredImageView and XBFilteredCameraView only.

The XBFilteredImageView is a subclass of XBImageFilters that has an `image` property. You can set an image to it and then set a filter shader with the method `setFilterFragmentShaderFromFile:error:` or multiple filters with `setFilterFragmentShadersFromFiles:error:`, then the view will be automatically redrawn. 

The XBFilteredCameraView is a subclass of XBImageFilters that allows you to filter the input image of a camera in real-time. It uses AVFoundation to capture the camera image. You can instantiate it, set some filters and call `startCapturing` to start the real-time rendering. You can also take a photo as an UIImage with the method `takeAPhotoWithCompletion:`.

## License

This project is under the MIT license (details in COPYRIGHT.txt). Do whatever you want with it and contributions of any form are very welcome.
