# ``Atoms``

Atomic approach state management and dependency injection for SwiftUI

## Additional Resources

- [GitHub Repo](https://github.com/ra1028/swiftui-atom-properties)

## Overview

Atoms offers a simple but practical capability to tackle the complexity of modern apps. It effectively integrates the solution for both state management and dependency injection while allowing us to rapidly build an robust and testable application.

Building state by compositing atoms automatically optimizes rendering based on its dependency graph. This solves the problem of performance degradation caused by extra re-render which occurs before you realize.

## Topics

### Atoms

- ``ValueAtom``
- ``StateAtom``
- ``TaskAtom``
- ``ThrowingTaskAtom``
- ``AsyncSequenceAtom``
- ``PublisherAtom``
- ``ObservableObjectAtom``
- ``ModifiedAtom``

### Modifiers

- ``Atom/select(_:)``
- ``Atom/changes``
- ``Atom/phase``

### Attributes

- ``KeepAlive``

### Property Wrappers

- ``Watch``
- ``WatchState``
- ``WatchStateObject``
- ``ViewContext``

### Views

- ``AtomRoot``
- ``AtomScope``
- ``Suspense``

### Values

- ``AsyncPhase``
- ``Snapshot``

### Contexts

- ``AtomContext``
- ``AtomWatchableContext``
- ``AtomTransactionContext``
- ``AtomViewContext``
- ``AtomTestContext``
- ``AtomUpdatedContext``
- ``AtomModifierContext``

### Internal System

- ``Atom``
- ``AtomStore``
- ``AtomModifier``
- ``SelectModifier``
- ``ChangesModifier``
- ``TaskPhaseModifier``
- ``AtomLoader``
- ``RefreshableAtomLoader``
- ``AsyncAtomLoader``
- ``ValueAtomLoader``
- ``StateAtomLoader``
- ``TaskAtomLoader``
- ``ThrowingTaskAtomLoader``
- ``AsyncSequenceAtomLoader``
- ``PublisherAtomLoader``
- ``ObservableObjectAtomLoader``
- ``ModifiedAtomLoader``
- ``AtomLoaderContext``
