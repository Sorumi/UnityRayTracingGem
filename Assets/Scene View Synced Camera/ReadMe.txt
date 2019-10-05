
This tiny script automatically aligns your in game camera with scene view (as Ctrl + Shift + F does),
so you'll always see the exact picture as you see in the editor, but with your own camera render settings.


Setting Up:

You're able to clone existing camera with custom settings, filters & etc. by selecting it and go to "GameObject/Scene View Synced Cam/Clone Selected Camera" or
create a new default one with "Add Scene View Synced Camera".
You can add (drag or "Add Component") this script to existing camera too.


Settings:

Disable On Play - Disables the game object, so you won't see image from this camera while in play mode.
Lock On Play - Disables alignment in play mode. (If you need this camera in play mode and you have scripts modyfying its transform - set to true).
Revert On Destroy - When removing script it restores gameobject position, rotation and camera settings to the moment when the script was initialized.


Deleting:

If you don't need this gameobject anymore just delete it, otherwise make sure "Revert On Destroy" is correctly set up: 
set true if you want to restore original transform and cam settings, false if you want to apply changes.
Then delete script component from this game object.

(!) Pay attention that only one script is allowed per scene, that's why adding a new script will remove all previous scripts.

