# Hetet - Godot 4 Mobile Platformer

Production-ready starter architecture for a child-friendly 2D platformer targeting Android tablets.

## Included Systems
- Modular scenes (`scenes/`) and scripts (`scripts/`)
- Double jump player controller
- Coins + HUD hooks
- Checkpoint + respawn + local save data
- Trap and puzzle reusable components
- Two worlds: Normal and Candy
- Villain intro/taunt system
- Final boss with multi-phase logic
- Procedural section generator for future AI-prompted expansion
- Mobile renderer + tablet stretch settings

## Suggested Next Steps
1. Wire touch input via on-screen buttons in `scenes/ui/MobileControls.tscn`
2. Add real art/audio assets in `assets/`
3. Create full level layouts with TileMap and collision layers
4. Add Android export preset (`export_presets.cfg`) and keystore
