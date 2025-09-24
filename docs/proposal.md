# TinyTapeout Project Proposal

## Project Overview
**Project Name:** [Insert Project Name]  
**Team Members:** Tolga Selcuk and Joshua Zhang 
**Date:** Sept 24, 2025

### Project Description
[Provide a brief description of your project, what it does, and its main functionality]

---

## 1. Block Diagram

```
[Insert block diagram here]
```

---

## 2. TT I/O Assignments

### Input Pins (8 total)
| Pin | Signal Name | Description |
|-----|-------------|-------------|
| 0   | pause       | Pauses the operation or output of the core logic |
| 1   | resume      | Resumes operation after a pause |
| 2   | speed_1     | Selects speed setting 1 (lowest speed) |
| 3   | speed_2     | Selects speed setting 2 |
| 4   | speed_3     | Selects speed setting 3 |
| 5   | speed_4     | Selects speed setting 4 |
| 6   | speed_5     | Selects speed setting 5 |
| 7   | speed_6     | Selects speed setting 6 (highest speed) |

### Output Pins (8 total)
| Pin | Signal Name | Description |
|-----|-------------|-------------|
| 0   | hsync       | VGA horizontal sync |
| 1   | B[0]        | Blue (least significant bit) |
| 2   | G[0]        | Green (least significant bit) |
| 3   | R[0]        | Red (least significant bit) |
| 4   | vsync       | VGA vertical sync |
| 5   | B[1]        | Blue (most significant bit) |
| 6   | G[1]        | Green (most significant bit) |
| 7   | R[1]        | Red (most significant bit) |

### Bidirectional Pins (8 total)

Unused

---

## 3. Projected Work Schedule

### Phase 1: Design & Planning (Week 1-2)
- [ ] Complete detailed design specification
- [ ] Finalize block diagram and I/O assignments
- [ ] Set up development environment
- [ ] Create test plan

### Phase 2: Implementation (Week 3-5)
- [ ] Implement core logic modules
- [ ] Develop input/output interfaces
- [ ] Create state machines (if applicable)
- [ ] Implement timing and control logic

### Phase 3: Testing & Verification (Week 6-7)
- [ ] Unit testing of individual modules
- [ ] Integration testing
- [ ] Timing verification
- [ ] Functional verification

### Phase 4: Final Integration (Week 8)
- [ ] Final system integration
- [ ] Performance optimization
- [ ] Documentation completion
- [ ] Final testing and validation

### Milestones
- **Week 2:** Design review and approval
- **Week 4:** Core functionality demonstration
- **Week 6:** Alpha version ready for testing
- **Week 8:** Final project submission