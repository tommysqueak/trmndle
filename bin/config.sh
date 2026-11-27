#############################################################################
### ONLINE-SCREENSAVER CONFIGURATION SETTINGS
#############################################################################

# folder that holds the screensavers
SCREENSAVERFOLDER=/mnt/us/linkss/screensavers

# In which file to store the downloaded image. Make sure this is a valid
# screensaver file. E.g. check the current screensaver folder to see what
# the first filename is, then just use this. THIS FILE WILL BE OVERWRITTEN!
SCREENSAVERFILE=$SCREENSAVERFOLDER/bg_ss00.png

# Whether to create log output (1) or not (0).
LOGGING=1

# Where to log to - either /dev/stderr for console output, or an absolute
# file path (beware that this may grow large over time!)
#LOGFILE=/dev/stderr
LOGFILE=/mnt/us/extensions/onlinescreensaver/log/onlinescreensaver.log

# the temporary file to download the screensaver image to
TMPFILE=/tmp/tmp.onlinescreensaver.png

TRMNL_BASE_URL=
TRMNL_API_KEY=
