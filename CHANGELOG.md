# 📜 Version History

## [6.2.3] - 2026-03-21
### Fixed
- Resolve various upload failures.  

## [6.2.2] - 2026-03-21
### Fixed
- Issue uploading new packages
### Added
- Force package inventory refresh

## [6.2.1] - 2026-01-03
### Changes
- More memory friendly upload process, especially for larger files.

## [6.2.0] - 2025-12-18
### Fixed
- Address issue #27, failed authentication with API clients.
### Added
- Add basic hardware, OS, and jamfcpr app useage collection. Data is sent anonymously to [TelemetryDeck](https:telemetrydeck.com) to aid in the development of the app. View 'About jamfcpr' to opt out of sending the data.
  
## [6.1.2] - 2025-10-24 
### Fixed
- Resolve issue that prevented the source dislay name, category, info, and notes from replicating.

## [6.1.1] - 2025-10-06 
### Fixed
- Resolve issue that could cause app to hang when the destination is a folder.
- Resolve issue when force sync is used when the destination is a folder.

## [6.1.0] - 2025-10-04  
### Fixed
- Issue with mounted shares. 
### Changes
- Miscellaneous updates to align with changes to the Jamf Pro API (cloud-distribution-point). 

## [6.0.3] - 2025-04-21 
### Fixed 
- Issue where file shares were improperly saved and might appear as a Jamf Pro server in other apps I've worked on.

## [6.0.2] - 2025-04-01
### Fixed
- Issue working with local folders and remove file shares. 
### Added
- Option to remount remote file share if it has already been mounted by another process.

## [6.0.1] - 2025-03-31
### Fixed
- Issue working with S3 distrobutions points. 
- Fix issue with API credentials.

## [6.0.0] - 2025-02-04
### Changes
- Requires Jamf Pro v11.5 or later. 
- Consolidated management of source/destination shares/distributions points. 
- More consistent handling of credentials. 
- Improved response times went querying for existing packages.

## Legacy Updates
- 2024-10-31 v5.2.2:  Resolve issue where replicate button remains disabled after listing packages when destination is a file share.

- 2024-10-23 v5.2.1:  Resolve permission issues when copying to a fileshare. Resolve issue when there is a space in the fileshare name. Fix potential issue where the app would hang at launch.

- 2024-10-11 v5.2.0:  Resolve some potential authentications issues. Transfer category (create if need be), info, and notes from source Jamf Pro to destination. Account privileges must now also include read and create categories.

- 2024-10-03 v5.1.1:  Upload (session) token renewal has been resolved. Single file uploads can now take over an hour to upload.

- 2024-09-25 v5.1.0:  Add support for files over 5GB. Due to an issue with token renewal the upload must complete within one hour. The amount of memory the app uses is directly related to the size of the file uploaded with the app memory usage greater than the size of the file.

- 2024-03-18 v5.0.0-b3:  Add support for AWS S3 distribution points. Fix potential issue uploading/downloading packages to JCDSs hosted outside the US. Fix issues when Save Only is selected.

- 2024-02-26 v4.1.2:  Fix issue (#23) where app would not save new server.

- 2024-02-26 v4.1.1:  Better performance/behavior when using an API client and switching client types. Minor UI updates, update app icon.

- 2024-02-09 v4.1.0:  File distribution points will be listed (when applicable) when connecting to a Jamf Pro server. Auto mounting/unmounting of file share distributions points. Resolve issues when using API client.

- 2024-01-02 v4.0.2:  Better error handling, better handling of concurrent operations, better handling of bearer token.

- 2024-01-02 v4.0.2-b1:  Redesign of the interface. Updated to be compatible with JCDS2 (only). Enable command line usage.

- 2022-11-19 v3.5.0:  Fix issue with bearer token only authentication to the Classic API. Changes to the UI, ability to hide username/password fields. Modify permissions check, user needs User Jamf Admin and Save With Jamf Admin privileges to migrate packages. Add information (when it was uploaded, account used to upload, and that is was uploaded with jamfCPR) to the Notes section for a package in Jamf Pro.

- 2022-07-18 v3.3.4:  Resolve issue with international characters and crash when clicking on an empty list of packages; issue #12.

- 2022-07-12 v3.3.3:  Resolve issue with destination information (URL/credentials) when running in Save Only mode. Destination information is no longer required with Save Only mode; issue #11.

- 2022-05-04 v3.3.2:  Resolve potential authentication issue with servers that have limited access configured.

- 2022-03-04 v3.3.1:  Increase stability. Only calculate checksum for selected packages. Provide feedback while checksums are calculated. Get list of packages from destination after retrieving source packages and identify packages not on the destination server. Support bearer token authentication to the Classic API. Retain selected items after comparing checksum/size. Added shortcut to open logs folder.

- 2021-12-08 v3.1.5:  Improved stability. Added animation while information is being retrieved from the destination server.

- 2021-07-16 v3.1.1:  Fixed issue (#7) where packages don't display first time app is used without clicking the Name or Size column header. Handle failed uploads (issue #9).

- 2021-06-30 v3.1.0:  Add ability to save passwords to the keychain. Add option to compare packages by size. Preserve compare results when sorting by name/size. Catch and report on failed uploads.

- 2021-06-22 v3.0.0:  Add support for using AWS (non-JCDS) as a source package distribution server. Allow up to 3 simultaneous uploads. Present different icons to identify missing packages or non-matching checksums between source and destination. Correct issue where JCDS was not identified if SSO was enabled and Replicate was clicked before Compare. Preserve display name while copying.

- 2021-06-06 v2.2.0:  Added ability to sort by Name or Size. Added check for destination JCDS being the principal distribution point, and warn if not.

- 2021-05-31 v2.1.2:  Tracking down miscellaneous hiccups. Add visual indication for packages with non-matching checksums (JCDS to JCDS only).

- 2021-05-21 v2.1.0: Fix crash that would result of spaces in the package name. Add check to ensure package size doesn't exceed JCDS limit (20GB). 

- 2021-05-12 v2.0.0: Move away from dbfileuploads endpoint, upload directly to the JCDS. Additional checks to verify authentication to the jamf server.

- 2021-04-13 v1.0.1: Fixed issue where packages would get deleted from a source AFP/SMB distribution point if being used as a source.

- 2021-03-28 v1.0.0: Fix issue where small (< ~1MB) packages failed to sync. Add ability to identify packages not on the destination server.

- 2021-03-27: Added option to force sync (ignore matching checksums), available by selecting "Force Sync" through the Options button.

- 2021-02-17: Fixed issued authenticating against Jamf Pro v10.27 to get a list of packages from the source server.
