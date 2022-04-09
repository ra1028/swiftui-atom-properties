# ``Atoms``

A declarative state management and dependency injection library for SwiftUI x Concurrency.

## Overview

The Atomic Architecture offers practical capabilities to manage the complexity of modern apps. It effectively integrates the solution for both state management and dependency injection while allowing us to rapidly building an application.

## Source Code

<https://github.com/ra1028/swiftui-atomic-architecture>

## Topics

### Atoms

- ``ValueAtom``
- ``StateAtom``
- ``TaskAtom``
- ``ThrowingTaskAtom``
- ``AsyncSequenceAtom``
- ``PublisherAtom``
- ``ObservableObjectAtom``

### Modifiers

- ``Atom/select(_:)``
- ``Atom/phase``

### Attributes

- ``KeepAlive``

### Property Wrappers

- ``Watch``
- ``WatchState``
- ``WatchStateObject``
- ``ViewContext``

### Contexts

- ``AtomContext``
- ``AtomWatchableContext``
- ``AtomRelationContext``
- ``AtomViewContext``
- ``AtomTestContext``

### Views

- ``AtomRoot``
- ``AtomRelay``
- ``Suspense``

### Values

- ``AsyncPhase``

### Debugging

- ``AtomObserver``
- ``AtomHistory``
- ``Snapshot``

### Internal System

- ``Atom``
- ``SelectModifierAtom``
- ``TaskPhaseModifierAtom``
- ``AtomHook``
- ``AtomStateHook``
- ``AtomTaskHook``
- ``AtomRefreshableHook``
- ``AtomHookContext``
- ``ValueHook``
- ``StateHook``
- ``TaskHook``
- ``ThrowingTaskHook``
- ``AsyncSequenceHook``
- ``PublisherHook``
- ``ObservableObjectHook``
- ``SelectModifierHook``
- ``TaskPhaseModifierHook``
