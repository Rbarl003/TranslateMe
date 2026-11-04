# Project 6 - *Talk Freely*

Submitted by: **Ritch Barlatier**

**Talk Freely** is an app that lets you type a word, phrase, or sentence and instantly translate it into one of twelve languages using Apple's on-device Translation framework, while keeping a running, erasable history of everything you've translated.

Time spent: **X** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] Users open the app to a TranslationMe home page with a place to enter a word, phrase or sentence, a button to translate, and another field that should initially be empty
- [x] When users tap translate, the word written in the upper field translates in the lower field. The requirement is only that you can translate from one language to another.
- [x] A history of translations can be stored (in a scroll view in the same screen, or a new screen)
- [x] The history of translations can be erased

The following **optional** features are implemented:

- [x] Add a variety of choices for the languages
- [x] Add UI flair

The following **additional** features are implemented:

- [x] Translation history persists across app launches (stored locally via `UserDefaults`), not just for the current session
- [x] "From" language supports automatic detection in addition to manual selection, so you don't have to know the source language in advance
- [x] A swap button exchanges the "From"/"To" languages and the input/output text in one tap
- [x] Each history entry records and displays the actual detected language pair for that translation, with flag icons
- [x] Translations run fully on-device via Apple's `Translation` framework, so no text leaves the device
- [x] Loading state (spinner + "Translating…") while a translation is in progress, with animated transitions when results and history entries appear

## Video Walkthrough

Here's a walkthrough of implemented user stories:
https://www.loom.com/share/9579091e14574cc8b9c1a92c937a8dd6

Here is a reminder on how to embed Loom videos on GitHub. Feel free to remove this reminder once you upload your README.

[Guide](https://www.youtube.com/watch?v=GA92eKlYio4)

## Notes

The trickiest part was getting the newer SwiftUI `Translation` framework's API right — specifically how `TranslationSession.Configuration` needs to be mutated or reconstructed to force a re-run when either the source/target languages or the input text change. Comparing the current configuration's `source`/`target` against the desired ones before deciding whether to call `invalidate()` or build a fresh `Configuration` was the key to making the language pickers and the swap button both retrigger translation correctly.

The project's coding guidelines also called for avoiding the Combine framework, so the translation history store uses the newer `@Observable` macro instead of `ObservableObject`/`@Published`, which also simplified the model a bit.

Separately, an existing file in the project (`LoginView.swift`) was missing `import SwiftUI`, which silently broke compilation for the whole target until it was added — a good reminder to always do a full build rather than trusting that unrelated files are fine.

## License

    Copyright 2026 Ritch Barlatier

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.# TranslateMe
