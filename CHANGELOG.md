# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Adds `QueueBus.has_adapter?` to check whether the adapter is set before setting it to resque. This will allow multiple adapters to be loaded without error.

### Changed
- Bump version dependency of queue-bus to at least 0.7
