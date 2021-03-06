# adjust_multicolor_image GUI
This GUI will allow you to reorient your multicolor image to make IDing easier.
For ID it is easiest to orient the worm so that it is on its right side, head facing left, and thus ventral chord on the bottom of the image. The GUI is slow, but you shouldn't have to do much more than crop/flip/rotate the image

NOTE: Cropping before doing any other adjustment should speed up time

The weight and gamma value can be set for each color independently.
The default values should be adequate

**Load:** loads an AML for adjusting

**Save:** saves the AML to the same file. This takes a minute.

**Crop:** Click-drag-release a rectangle around the head. Removes the portion of the image not in the box

**Subtract Background:** Click points sequentially to create a polygon around a region of space with no fluorescence. This is very useful for dim or bleached images.

**Select Outliers:** Click points sequentially to create a polygon around the neurons. Sets all other values to 0

**Clear Outliers:** Removes previous selections of outliers

**Reset Sliders:** Resets all sliders to the last saved value

**Flip X,Y:** In addition to flipping the labeled dimension, each flip also flips the Z dimension. Flips in this way act like physically flipping the worm, and guarantee that if the worm is facing to the left with ventral side down, it is lying on its right side. In combination with Rotate one of these is unnecessary but they're included for convenience.

**Rotate:** Rotates around the Z axis.

#### Adjustments are applied to the image in the following order:
* Crop
* Background Subtraction
* Gamma
* Weights
* Flip X
* Flip Y
* Rotation
