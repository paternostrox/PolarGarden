# The Polar Garden
An experiment on procedural generation in spherical coordinates.

## Description

The project was made to practice my skills in math, OpenGL, GDScript and to mess with online multiplayer using RPCs.

Do not expect it to be beautiful! :sweat_smile:

## The system

This experiment is composed by two parts, the client project (this one) and the server project that can be found in [here](https://github.com/paternostrox/PolarGarden-Server).



<img src="https://user-images.githubusercontent.com/19597048/236262658-fbce294f-1c45-409e-898e-9e213ad3dd50.png" width="600">

|  | Example 1 | Example 2 | Example 3 |
| --- | --- | --- | --- |
| Inflorescence Equation |  $(r = a \|cos(\frac{p}{q}.\theta)\|, \theta = \theta, \phi = 1)$ where $a,p,q,\theta \in \mathbb{I}$ | $(r = a cos(\frac{p}{q}.\theta), \theta = \theta, \phi = \theta)$ where $a,p,q,\theta \in \mathbb{I}$ | $(r = a.arcsen(cos(n.\theta + 0.97)), \theta = \theta, \phi = \theta)$ where $a,n,\theta \in \mathbb{R}$
Picture |<img src="https://user-images.githubusercontent.com/19597048/236263085-1532607a-3b9f-432e-906a-b2c36f97a94d.png" width="200" height="200">|<img src="https://user-images.githubusercontent.com/19597048/236290781-716c97e3-9b95-40d3-b487-2045899ce437.png" width="200" height="200">|<img src="https://user-images.githubusercontent.com/19597048/236263245-bf94632e-d164-44e8-a722-663c30820408.png" width="200" height="200">
