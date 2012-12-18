Muniverse
==========

**Muniverse is the fastest way to find arrival times for San Francisco Muni busses, trains and historic street cars.**

![Nearby Map](https://raw.github.com/nickoneill/Muniverse2/master/Screenshots/NearbyMap.png) ![Nearby Stop Detail](https://github.com/nickoneill/Muniverse2/raw/master/Screenshots/MapStopDetail.png) ![Subway Station Detail](https://github.com/nickoneill/Muniverse2/raw/master/Screenshots/StationDetail.png)

[Nick O'Neill](http://nickoneill.name) (code as [Launch Apps](http://launchapps.net)) and [Jamison Wieser](http://jamisonwieser.com/) (UI/UX as [Fat Trash Design](http://fattrash.com)) made this. We're both contractors working in San Francisco and you can reach out to us if you need our services, collectively or independently.

It's been through a number of code and design iterations, the current app is freshly written to take advantage of new improvements in Objective-C and UIKit.

While our project is focussed on the San Francisco Muni system, over 100 transit systems provide real-time arrival information using the same NextBus API that SF Muni uses.

We are making our code available so others can examine and hopefully improve on their own projects and ultimately make real-time arrival information more accessible.

All code for Muniverse is licensed under the MIT license (see below). Please copy, paste, improve or otherwise use the code as you see fit. HOWEVER, any graphics in the repository are not included under the license. Please don't use our graphics for your project without asking, that wouldn't be nice.

The JSON file we use to populate the data in the app includes a reduced number of available lines. Our aim with this is to prevent unscrupulous types from submitting the same code to the App Store with little or no changes. Otherwise, the code here is completely functional.

If you are interested in adapting the code to your local transit system or have any other questions or comments, feel free to contact either of us.

Muniverse uses these third party components:
* [TouchXML](https://github.com/TouchCode/TouchXML) for NextBus API parsing
* [AFNetworking](http://afnetworking.com/) for all network requests
* [MKMapView+ZoomLevel](http://troybrant.net/blog/2010/01/set-the-zoom-level-of-an-mkmapview/) from Troy Brant
* [Button images](http://nathanbarry.com/designing-buttons-ios5/) from Nathan Barry

License
-------

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.