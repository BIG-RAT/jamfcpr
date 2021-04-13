# Jamf Cloud Package Replicator 

Download: [jamfcpr](https://github.com/BIG-RAT/jamfcpr/releases/download/current/jamfcpr.zip)

![alt text](./images/jamfcpr.png "jamfcpr")

Copy packages from a directory (local/mounted share/drive) or from one JCDS to another JCDS with jamfcpr.app.  You're able to replicate packages using the following:

* Browse to a local directory or mounted share.
* Enter the URL of a Jamf Server with an on premise distribution point (DP) as the master.  Click the List button and the DP is mounted and available packages are displayed.
* Enter the URL of a Jamf Server with a JCDS as the master in the Source URL field.  Click the List button and available packages on the JCDS will be listed.
* Hold the option key while clicking the List button to select a non-master distribution point to replicate from.

![alt text](./images/select.png "select")

To identify packages not currently on the destination JCDS click the Compare button.


![alt text](./images/compare.png "compare")


Once you have a list of packages select the package(s) you wish to replicate and click the Replicate button.  For the first two methods packages are replicated from the directory/share to the JCDS.  For the last method, where a JCDS is the source, packages are downloaded to ~/Downloads/jamfcpr/, then uploaded to the destination JCDS.  By default, once the upload is complete the local copy is deleted.  This behavior can be changed by selecting Save from the Options button.  In addition you're able to select Save Only, i.e. packages will only be downloaded.
Checksums are used to determine if the package to upload differs from what is already on the JCDS. 

* To override this behavior, and force package(s) to sync, select "Force Sync" under the Options button.

Note, percents shown represent percent of current file being uploaded/downloaded.  The status bars represent the progress of all transfers.  

Application log is available in ~/Library/Logs/jamfcpr/

## History

- 2021-04-13 v1.0.1: Fixed issue where packages would get deleted from a source AFP/SMB distribution point if being used as a source.

- 2021-03-28 v1.0.0: Fix issue where small (< ~1MB) packages failed to sync.  Add ability to identify packages not on the destination server.

- 2021-03-27: Added option to force sync (ignore matching checksums), available by selecting "Force Sync" through the Options button.

- 2021-02-17: Fixed issued authenticating against Jamf Pro v10.27 to get a list of packages from the source server.
