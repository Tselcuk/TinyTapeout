# TinyTapeout Project Proposal

## Project Overview

**Project Name:** WatPixels
**Team Members:** Tolga Selcuk and Joshua Zhang
**Date:** Sept 24, 2025

### Project Description

We are developing a demoscene project that generates visually engaging, overlapping patterns. The display will evolve over time and in a final scene featuring "Waterloo Engineering" and the uWaterloo emblem.

---

## 1. Block Diagram

![Block Diagram](image/proposal/diagram.png)

---

## 2. TT I/O Assignments

### Input Pins (8 total)

| Pin | Signal Name | Description                                      |
| --- | ----------- | ------------------------------------------------ |
| 0   | pause       | Pauses the operation or output of the core logic |
| 1   | resume      | Resumes operation after a pause                  |
| 2   | speed_1     | Selects speed setting 1 (lowest speed)           |
| 3   | speed_2     | Selects speed setting 2                          |
| 4   | speed_3     | Selects speed setting 3                          |
| 5   | speed_4     | Selects speed setting 4                          |
| 6   | speed_5     | Selects speed setting 5                          |
| 7   | speed_6     | Selects speed setting 6 (highest speed)          |

### Output Pins (8 total)

| Pin | Signal Name | Description                   |
| --- | ----------- | ----------------------------- |
| 0   | hsync       | VGA horizontal sync           |
| 1   | B[0]        | Blue (least significant bit)  |
| 2   | G[0]        | Green (least significant bit) |
| 3   | R[0]        | Red (least significant bit)   |
| 4   | vsync       | VGA vertical sync             |
| 5   | B[1]        | Blue (most significant bit)   |
| 6   | G[1]        | Green (most significant bit)  |
| 7   | R[1]        | Red (most significant bit)    |

### Bidirectional Pins (8 total)

Unused

---

## 3. Projected Work Schedule

### Phase 1: Design & Planning (Week 1-2)

- [ ] Complete detailed design specification
- [ ] Finalize block diagram and I/O assignments

### Phase 2: Implementation (Week 3-7)

- [ ] **Pattern Generation Engine**
  - Implement mathematical pattern generators (spirals, waves, fractals)
  - Create pattern blending and mixing algorithms
  - Develop time-based pattern evolution logic
- [ ] **Animation System**
  - Implement frame counter and timing control
  - Create smooth transitions between pattern phases
  - Develop speed control based on input pins
- [ ] **Text Rendering Engine**
  - Implement character bitmap storage and lookup
  - Create text positioning and rendering logic
  - Develop "Waterloo Engineering" and emblem display
- [ ] **State Machine Controller**
  - Implement pause/resume functionality
  - Create scene transition logic
  - Develop overall system coordination

### Phase 3: Final Integration (Week 8)

- [ ] Final system integration
- [ ] Performance optimization
- [ ] Documentation completion
- [ ] Final testing and validation