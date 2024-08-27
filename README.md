# Day Night Cycle For Godot 4
Actually good day and night cycle for the Godot Engine.  

To use simply import the project into godot and take out the world environment (and the directional light)
- Make sure that the name of the directional light is the same as what the script on the worldenvironment is accessing.
- Also you can easily separate the day night cycle from the main scene by moving the directional light as well as the worldwnvironent to a separate scene.
- If your engine is constantly crashing, the problem might be the grass in the scene, not the skybox, in that case just delete the grass and terrain from the scene.
- If you still cannot open the scene, you can try copying the code and the stylizedskyplugin from my project and putting it into your own project, that way you dont have to open your editor.
