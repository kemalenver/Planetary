# Kepler/Planetary Architecture Documentation

## Overview

Kepler (branded as "Planetary") is an iOS music visualization application that transforms a user's music library into an interactive 3D universe. The application uses the Cinder creative coding framework to render artists as planets, albums as moons, and tracks as smaller orbital bodies in a cosmic visualization.

---

## Table of Contents

1. [Application Entry Point](#application-entry-point)
2. [Core Components](#core-components)
3. [Music Visualization System](#music-visualization-system)
4. [Rendering Pipeline](#rendering-pipeline)
5. [Data Flow](#data-flow)
6. [Interaction Model](#interaction-model)
7. [Third-Party Dependencies](#third-party-dependencies)
8. [Design Patterns](#design-patterns)

---

## Application Entry Point

### KeplerApp (`src/KeplerApp.cpp`, `src/KeplerApp.h`)

The main application class extends `AppCocoaTouch` and manages the entire iOS application lifecycle.

**Two-Phase Initialization:**

1. **Phase 1 - `setup()`**: Fast initialization
   - Creates BloomScene (UI controller)
   - Loads loading screen textures
   - Sets up orientation handling
   - Initializes state management

2. **Phase 2 - `remainingSetup()`**: Deferred to first update cycle
   - Loads full texture set via TextureLoader
   - Initializes World (3D node hierarchy)
   - Sets up UI layers and controls
   - Initializes particle system

**Key Members:**
- `mState`: Application state management (filters, selections, playback)
- `mData`: Music library data (artists, playlists, metadata)
- `mWorld`: 3D visualization space containing all music nodes
- `mIpodPlayer`: Direct connection to iOS music library
- `mBloomSceneRef`: Root of UI scene graph

---

## Core Components

### 1. Hierarchical Node System

The application visualizes music libraries as a 4-level hierarchy using polymorphic Node classes:

```
Level 1: NodeArtist (suns/planets - 1 per artist)
├── Level 2: NodeAlbum (orbiting each artist)
│   └── Level 3: NodeTrack (orbiting each album)
└── Visual Elements: Names, orbits, glows, atmospheres
```

#### Base Class: Node (`Headers/World/Nodes/Node.h`, `Source/World/Nodes/Node.cpp`)

Core functionality for all music visualization nodes:
- **Properties**: position, velocity, orbit parameters, color, radius
- **Animation**: orbital motion, scale changes, camera distance calculations
- **Hierarchy**: parent-child relationships
- **Rendering**: virtual methods for planet, rings, atmosphere rendering
- **Text**: async name texture generation via task queue

#### NodeArtist (`Headers/World/Nodes/NodeArtist.h`, `Source/World/Nodes/NodeArtist.cpp`)

Represents an artist in the music library.
- **Visual Style**: Large planet with star glow and eclipse effects
- **Rendering Methods**: `drawPlanet()`, `drawExtraGlow()`, `drawAtmosphere()`
- **Data**: Stores artist playlist reference and album count

#### NodeAlbum (`Headers/World/Nodes/NodeAlbum.h`, `Source/World/Nodes/NodeAlbum.cpp`)

Represents albums for a specific artist.
- **Visual Style**: Planet with album art texture, optional rings and clouds
- **Features**: Shadow rendering, atmosphere effects
- **Data**: Album artwork surface, release year, total track duration

#### NodeTrack (`Headers/World/Nodes/NodeTrack.h`, `Source/World/Nodes/NodeTrack.cpp`)

Represents individual tracks.
- **Visual Style**: Small moon with track-specific rendering
- **Features**: Playback progress with animated playhead ring
- **Data**: Album art, play count, audio visualization

### 2. World (`Headers/World/World.h`, `Source/World/World.cpp`)

Manages the entire 3D scene of music nodes.

**Responsibilities:**
- **Initialization**: Creates NodeArtist hierarchy from iPod playlists
- **Node Management**: Stores artists in vectors, indexed by ID in maps
- **Filtering**: Applies Filter objects to show/hide nodes based on criteria
- **Visualization Components**:
  - Stars (artist nodes rendered as billboards)
  - StarGlows (bloom effect on stars)
  - OrbitRing (visual rings showing orbits)
  - PlanetRing (rings around planets)
  - Constellation (lines connecting filtered nodes)
  - BloomSphere LOD objects (Hi, Md, Lo, Ty resolution levels)

### 3. State Management (`Headers/State.h`, `Source/State.cpp`)

Central state management with observer pattern callbacks.

**State Tracked:**
- Alpha Filter (character-based filtering A-Z)
- Playlist Filter (filter by specific playlists)
- Node Selection (currently selected node)
- Filter Modes (toggle between alpha and playlist filtering)

**Callbacks:** Observer pattern for state changes propagation

### 4. Data Management (`Headers/Data.h`, `Source/Data.cpp`)

Handles music library loading.

**Responsibilities:**
- Load Artists and Playlists from iPod library
- Track loading progress
- Maintain character-to-artist-count mapping for UI

### 5. Filter System (`Headers/Filters/Filter.h`)

Abstract interface for node filtering with implementations for letter and playlist filtering.

**Interface:**
- `testArtist()`, `testAlbum()`, `testTrack()`

**Implementations:**
- `LetterFilter`: Filter by artist name starting letter
- `PlaylistFilter`: Filter by playlist membership

Applied via `World::setFilter()`

---

## Music Visualization System

### Visual Mapping

The visualization treats the music library as a **3D planetary system**:

| Music Entity | Visual Representation | Properties |
|--------------|----------------------|------------|
| Artists | Large planets (stars) | Color from name hash, size from popularity |
| Albums | Medium planets | Orbit artists, show album art, have optional rings |
| Tracks | Small moons | Orbit albums, show playback progress |

**Visual Properties:**
- **Size**: Represents popularity (play count, release year)
- **Color**: Hash of name (unique per artist)
- **Position**: Orbital mechanics (period, radius, angle)
- **Animation**: Real-time playback visualization

### Audio Integration

Uses `CinderIPodPlayer` block for iOS music integration:
- Direct iOS MediaPlayer framework access
- Track current playing track/album/artist
- Update NodeTrack playhead visualization in real-time
- Callbacks for track changes, playback state changes

### Particle Effects

**ParticleController** manages visual feedback:
- Particles emit from selected nodes
- Dust provides motion trails
- Visual feedback for interaction

---

## Rendering Pipeline

### Three-Tier Rendering Architecture

#### A. 3D Scene Rendering (World)

```
setup() → initNodes(artists)
update() → position/scale all nodes + camera
drawStarsVertexArray() → Artist nodes as billboards
drawOrbitRings() → Orbital paths
drawNames() → Text labels
drawPlanet() → Individual planet textures
drawRings() → Planet rings
drawTouchHighlights() → Selection feedback
drawConstellation() → Lines between filtered nodes
```

#### B. Camera System

- **Type**: `CameraPersp` (3D perspective camera)
- **Navigation**:
  - Arcball: Touch-based rotation
  - Pinch-to-zoom: Scale and perspective adjustment
  - Auto-focus: Flying to selected nodes
  - FOV management: 55-80 degrees

#### C. 2D UI Overlay (BloomScene + BloomNode hierarchy)

```
BloomScene (root, receives touch events)
├── OrientationNode (handles device rotation)
│   ├── LoadingScreen
│   └── MainBloomNode
│       ├── UiLayer
│       │   ├── PlayControls (playback, track info)
│       │   ├── AlphaChooser (letter filter UI)
│       │   ├── PlaylistChooser (playlist selection)
│       │   └── SettingsPanel (toggles & options)
│       ├── HelpLayer
│       ├── NotificationOverlay
│       ├── Vignette (screen edges darkening)
│       └── ParticleController
```

#### D. Texture System

**TextureLoader**: Async threaded loading of:
- Star glows, eclipse effects
- Planet textures, cloud textures
- Atmosphere effects
- UI buttons, gradients
- Galaxy background dome

#### E. Visual Effects

- **BloomGl**: Billboard rendering and batching system
- **BloomSphere**: Sphere mesh LOD objects (4 quality levels)
- **Vignette**: Darkened edges (optional visual effect)
- **Galaxy**: Background spiral galaxy rendering

---

## Data Flow

### Overall Data Flow Architecture

```
iOS Music Library
       ↓
CinderIPodPlayer (mIpodPlayer)
       ↓
Data (mData.mArtists, mData.mPlaylists)
       ↓
World::initNodes() → Creates NodeArtist hierarchy
       ↓
State (mState.mSelectedNode, mState.mAlphaChar)
       ↓
Filter (mFilterRef) → Sets node visibility
       ↓
World::update() & World::updateGraphics()
       ↓
[3D Rendering] + [UI Rendering] (parallel)
```

---

## Interaction Model

### Touch Input Flow

```
User Touch Input
    ↓
BloomScene::touchesBegan/Moved/Ended (UI priority)
    ↓
UiLayer::touchBegan() → Check buttons/sliders
    ↓
If UI handled → BloomSceneEventRef callbacks
    If not → KeplerApp::touchesBegan() → checkForNodeTouch()
    ↓
Ray casting against nodes (3D world)
    ↓
World::selectHierarchy(artistId, albumId, trackId)
    ↓
State::setSelectedNode(node) → broadcasts callback
    ↓
KeplerApp::onSelectedNodeChanged(node)
    ↓
Update camera target and animation
    ↓
Render new selection state
```

### Playback Feedback Loop

```
User taps Play/Previous/Next (PlayControls)
    ↓
mIpodPlayer.play()/previousTrack()/nextTrack()
    ↓
iOS Music Framework plays audio
    ↓
KeplerApp::onPlayerTrackChanged() callback
    ↓
World::updateIsPlaying(artistId, albumId, trackId)
    ↓
NodeTrack::updateAudioData(playheadTime)
    ↓
NodeTrack re-renders playhead ring
```

### Camera Control

```
KeplerApp::updateCamera() every frame:
- Applies Arcball rotation (mArcball.getQuat())
- Manages zoom (mZoomFrom/Dest, mCamDist, mCamDistDest)
- Pinch gesture adjusts mPinchPer (0=pinched, 1=spread)
- Updates mEye, mCenter, mUp vectors
- Flies to selected nodes with tween
```

---

## Third-Party Dependencies

### Cinder Framework

Core graphics and application framework located in `cinder86/` directory.

**Key Modules:**
- **Graphics**: `cinder/gl/` - OpenGL rendering
- **Math**: `cinder/Vector.h`, `cinder/Matrix.h`, `cinder/Camera.h`
- **Input**: `cinder/app/TouchEvent.h`
- **Utilities**: Font, Image, Perlin noise
- **Camera**: Arcball camera control

### Custom Blocks (Modular Extensions)

#### 1. BloomScene (`Blocks/BloomScene/`)
- Scene graph system (BloomNode, BloomScene)
- Touch event routing
- Transform hierarchy management

#### 2. CinderIPod (`Blocks/CinderIPod/`)
- iOS MediaPlayer wrapper
- Track/Playlist/Artist data structures
- Album art retrieval
- Playback state management

#### 3. CinderIPodPlayer (`Blocks/CinderIPod/`)
- High-level player interface
- Playback control (play, pause, skip)
- Shuffle and repeat modes
- Track/library change callbacks

#### 4. CinderOrientation (`Blocks/CinderOrientation/`)
- Device orientation detection
- Portrait/Landscape handling

#### 5. CinderGestures (`Blocks/CinderGestures/`)
- Pinch gesture recognition
- Multi-touch support

#### 6. BloomTasks (`Blocks/BloomTasks/`)
- Task queue for async operations
- Name texture rendering on UI thread

### Boost Library

Included with Cinder, used for:
- `boost/foreach.hpp` - Range iteration
- `boost/unordered_map.hpp` - Hash maps for batching

---

## Design Patterns

### 1. Observer Pattern
**State** class uses callbacks for state change notifications (selected nodes, filters, etc.)

### 2. Scene Graph
**BloomNode** hierarchy for UI with parent-child transform propagation

### 3. Polymorphism
**Node** base class with **NodeArtist/Album/Track** specializations for different visual behaviors

### 4. Smart Pointers
`shared_ptr` for memory management (`BloomNodeRef`, etc.)

### 5. Task Queue
Async texture loading and UI thread operations via **BloomTasks**

### 6. Level of Detail (LOD)
Sphere meshes at 4 quality levels (Hi, Md, Lo, Ty) for performance optimization

### 7. Vertex Arrays
Pre-built geometry for stars, orbits, constellations using VBOs/vertex arrays for efficient rendering

### 8. Batching
**BloomGl** batches same-texture geometry together to minimize draw calls

---

## Global Configuration

### Constants (`Headers/Helpers/Globals.h`)

**Hierarchy Levels:**
- `G_ARTIST_LEVEL = 2`
- `G_ALBUM_LEVEL = 3`
- `G_TRACK_LEVEL = 4`

**Camera:**
- `G_DEFAULT_FOV = 60°`
- `G_INIT_CAM_DIST = 250`

**Sphere LOD:**
- Hi: 128 vertices
- Md: 64 vertices
- Lo: 32 vertices
- Ty: 16 vertices

**Visual Options:**
- `G_DRAW_RINGS`
- `G_DRAW_TEXT`

**Performance (device-dependent):**
- `G_NUM_PARTICLES = 160`
- `G_NUM_DUSTS = 5000`

**Dynamic Globals:**
- `G_ZOOM`: Current zoom level based on hierarchy depth
- `G_CURRENT_LEVEL`: Which hierarchy level user is viewing
- `G_DEBUG`: Debug visualization toggle

---

## File Structure Summary

### Core Application
- `KeplerApp.cpp/h` - Main application (88KB implementation)
- `World.cpp/h` - Scene management
- `State.cpp/h` - App state, callbacks
- `Data.cpp/h` - Library loading

### Node Hierarchy
- `Node.cpp/h` - Base class (13KB)
- `NodeArtist.cpp/h` - Artist visualization
- `NodeAlbum.cpp/h` - Album visualization
- `NodeTrack.cpp/h` - Track visualization

### UI System
- `UiLayer.cpp/h` - UI container
- `PlayControls.cpp/h` - Playback UI
- `SettingsPanel.cpp/h` - Settings
- `AlphaChooser.cpp/h` - Letter filter UI
- `PlaylistChooser.cpp/h` - Playlist filter UI

### Visualization
- `Galaxy.cpp/h` - Background rendering
- `BloomGl.h` - Rendering utilities
- `Stars.h`, `StarGlows.h` - Vertex array managers
- `OrbitRing.h`, `PlanetRing.h` - Ring rendering
- `ParticleController.cpp/h` - Particle system
- `Vignette.cpp/h` - Visual overlay

### Supporting
- `Filter.h` - Filter interface
- `Device.h` - Device detection
- `Globals.h` - Constants

---

## Summary

Kepler/Planetary creates a sophisticated interactive visualization where music library metadata is mapped to an astronomical metaphor. The architecture separates concerns between:

1. **Data Layer**: Music library loading and management
2. **Model Layer**: Hierarchical node system representing artists/albums/tracks
3. **View Layer**: 3D world rendering and 2D UI overlay
4. **Controller Layer**: State management, interaction handling, and camera control

The separation between 3D scene management (World) and 2D UI (BloomScene) allows independent updating and rendering of both systems, while the observer pattern ensures consistent state across all components.
