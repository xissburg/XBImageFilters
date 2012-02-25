# XBImageFilters

XBImageFilters allows you to obtain filtered versions of any image or from the camera in realtime. It uses OpenGL ES 2 to filter the images through fragment shaders you write yourself so you can filter your images in whatever way you want and it is super fast.

![Luminance](http://xissburg.com/images/XBImageFilters.png)

In this screenshot of the sample we have on the top half of the screen a regular UIImageView with contentMode set to UIViewContentModeTop, and on the bottom half a XBFilteredImageView with the same image with contentMode set to UIViewContentModeBottom and a filter [a GLSL fragment shader] that outputs the luminance of the pixel color.

![Gaussian Blur](http://xissburg.com/images/XBImageFiltersGaussianBlur.png)

Convoluted Gaussian Blur, an example of a multi-pass filter. It uses two fragment shaders for this, VGaussianBlur.glsl, HGaussianBlur.glsl. First, it uses VGaussianBlur to perform a vertical blur and the resulting image is stored in an OpenGL texture, then it uses HGaussianBlur to apply a horizontal blur in the previous texture that it rendered into. As a result we have a proper Gaussian Blur with a radial kernel. 

## Project Status

This project is in a very early stage of development so not all features advertised are functional yet.
