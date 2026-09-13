# NextDesk Remote native client

Native Windows client derived from RustDesk and built by the official RustDesk Windows pipeline.

## Product configuration

- Application identity: `NextDeskRemote`
- Product display name: `NextDesk Remote`
- ID/relay host: `164.68.96.241`
- RustDesk server public key: embedded at build time
- Target: Windows x64
- Output: self-contained portable EXE and MSI
- Current NextDesk release: 1.4.10
- Web protocol: rustdesk://, registered to the branded NextDesk Remote executable

The build is intentionally isolated from the NextDesk production application and repositories.

## License

RustDesk is licensed under AGPL-3.0. This fork and its complete corresponding source remain available under the same license. See `LICENCE` and upstream notices.
