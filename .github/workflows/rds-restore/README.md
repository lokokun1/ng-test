# RDS Restore

Pipeline for restoring RDS using snapshot and PITR when available

User selects

* environment
* database
* time day offset hour minute

The system builds the requested time in Israel timezone and converts it to UTC

Before restore the pipeline checks if PITR is actually available

If PITR exists it restores to the requested point in time

If PITR is not available it automatically falls back to snapshot restore

After restore the database can be swapped with the original instance if needed

Finally the state is synced using Terragrunt

Note
PITR depends on EarliestRestorableTime and LatestRestorableTime
In our environments PITR is not always available even when backups exist
In such cases snapshot is used as the default recovery method

All inputs are controlled via dropdowns to reduce human errors
