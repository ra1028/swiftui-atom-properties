# ``Atoms``

Atomic approach state management and dependency injection for SwiftUI

## Additional Resources

- [GitHub Repo](https://github.com/ra1028/swiftui-atom-properties)

## Overview

Atoms offer a simple but practical capability to tackle the complexity of modern apps. It effectively integrates the solution for both state management and dependency injection while allowing us to rapidly build a robust and testable application.

Building state by compositing atoms automatically optimizes rendering based on its dependency graph. This solves the problem of performance degradation caused by extra re-render which occurs before you realize.

## Topics

### Atoms

- ``ValueAtom``
- ``StateAtom``
- ``TaskAtom``
- ``ThrowingTaskAtom``
- ``AsyncPhaseAtom``
- ``AsyncSequenceAtom``
- ``PublisherAtom``
- ``ObservableObjectAtom``
- ``ModifiedAtom``

### Modifiers

- ``Atom/changes``
- ``Atom/changes(of:)``
- ``Atom/animation(_:)``
- ``TaskAtom/phase``
- ``ThrowingTaskAtom/phase``

### Effects

- ``AtomEffect``
- ``AtomEffectBuilder``
- ``InitializingEffect``
- ``InitializeEffect``
- ``UpdateEffect``
- ``ReleaseEffect``

### Attributes

- ``Scoped``
- ``KeepAlive``
- ``Refreshable``
- ``Resettable``

### Property Wrappers

- ``Watch``
- ``WatchState``
- ``WatchStateObject``
- ``ViewContext``

### Views

- ``AtomRoot``
- ``AtomScope``
- ``AtomDerivedScope``
- ``Suspense``

### Values

- ``AsyncPhase``
- ``Snapshot``
- ``DefaultScopeID``

### Contexts

- ``AtomContext``
- ``AtomWatchableContext``
- ``AtomTransactionContext``
- ``AtomViewContext``
- ``AtomTestContext``
- ``AtomCurrentContext``

### Misc

- ``Atom``
- ``AsyncAtom``
- ``AtomStore``
- ``AtomModifier``
- ``AsyncAtomModifier``
- ``ChangesModifier``
- ``ChangesOfModifier``
- ``TaskPhaseModifier``
- ``AnimationModifier``
- ``AtomProducer``
- ``AtomRefreshProducer``

### Deprecated

- ``EmptyEffect``
- ``MergedEffect``
