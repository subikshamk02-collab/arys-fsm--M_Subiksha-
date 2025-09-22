# FSM: Automatic Theme Park Ride Safety System

## Project Overview

This project implements a synchronous finite state machine (FSM) to manage safety in an autonomous theme park ride. The system continuously monitors key safety inputs such as seat restraint status, braking systems, queue sensors, and vibrations. Based on these inputs, the FSM transitions between defined operational states to ensure safe and reliable ride control.

The FSM is implemented in SystemVerilog and tested using EDA Playground. It includes debounce logic, fault persistence detection, fault masking, and fault prioritization to handle both transient and critical fault conditions in a reliable and deterministic way.

## FSM States and Transitions

### States

- **Normal**: All systems operating normally.
- **Warning**: A fault has been detected but is not yet critical.
- **Fault**: A persistent or high-priority fault has occurred.
- **Shutdown**: A critical fault or timeout condition has occurred. System must stop.

### State Transitions

- **Normal → Warning**: Triggered when any fault input becomes active after debouncing and masking.
- **Warning → Normal**: Triggered when all fault inputs are cleared.
- **Warning → Fault**: Triggered by a restraint or brake fault (high-priority), or if any fault persists beyond a defined number of cycles.
- **Fault → Warning**: Triggered when all faults clear before the shutdown timeout.
- **Fault → Shutdown**: Triggered if a fault persists for too long or a critical (restraint) fault occurs.
- **Shutdown → Shutdown**: Terminal state, latched after entry.

## Key Features

- Fully synchronous FSM (clock-driven)
- Input signal debouncing to filter transient glitches
- Per-input masking (to ignore faults during maintenance, for example)
- Fault persistence tracking (using cycle counters)
- Fault code output based on priority
- Alarm output signal active when not in Normal state

## Inputs

- `vibration_raw`: Raw vibration fault input
- `queue_raw`: Raw queue sensor input
- `brake_raw`: Brake system fault input
- `restraint_raw`: Seat restraint fault input
- `mask_*`: One mask signal per input to disable its effect

## Parameters

- `DEBOUNCE_CYCLES = 3`: Minimum stable cycles to confirm a signal change
- `PERSIST_CYCLES = 5`: Number of cycles a fault must persist to escalate from Warning to Fault
- `SHUTDOWN_TIMEOUT = 20`: Maximum cycles allowed in Fault before forcing Shutdown

## Outputs

- `state`: Current FSM state (Normal, Warning, Fault, Shutdown)
- `alarm`: High in any non-Normal state
- `fault_code`: Indicates the most critical active fault
    - 1: Restraint
    - 2: Brake
    - 3: Vibration
    - 4: Queue
    - 0: No fault



