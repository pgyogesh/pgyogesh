import argparse
import gzip
import datetime
import os
import logging
import tabulate
from collections import deque
import threading
import itertools
import sys
import time

parser = argparse.ArgumentParser()
parser.add_argument("-t", "--from_time", metavar= "MMDD HH:MM", dest="start_time", help="Specify start time in quotes")
parser.add_argument("-T", "--to_time", metavar= "MMDD HH:MM", dest="end_time", help="Specify end time in quotes")
parser.add_argument("-d", "--duration", metavar="DURATION", help="Specify duration in minutes. Eg: --duration 10m")
parser.add_argument('--types', metavar='LIST', help="""Comma separated list of log types to include. \n Available types: \n\t pg (PostgreSQL), \n\t ts (TServer), \n\tms (Master)""")
parser.add_argument("--nodes", metavar="LIST", help="Comma separated list of nodes to include. Eg: --nodes n1,n2")
parser.add_argument("--debug", action="store_true", help="Print debug messages")

# Function to display the rotating spinner
def spinner():
    for c in itertools.cycle(['|', '/', '-', '\\']):
        if done:
            break
        sys.stdout.write('\r Looking for files within time range' + c)
        sys.stdout.flush()
        time.sleep(0.1)
    sys.stdout.write('\rDone!     \n')

# Function to parse duration
def parse_duration(duration):
    if not duration:
        return None
    try:
        if duration[-1] == 'm':
            return datetime.timedelta(minutes=int(duration[:-1]))
        elif duration[-1] == 'h':
            return datetime.timedelta(hours=int(duration[:-1]))
        elif duration[-1] == 'd':
            return datetime.timedelta(days=int(duration[:-1]))
        else:
            raise ValueError
    except ValueError:
        raise ValueError("Invalid duration format. Use 'm' for minutes, 'h' for hours, and 'd' for days")

def getLogFilesFromCurrentDir():
    logFiles = []
    logDirectory = os.getcwd()
    for root, dirs, files in os.walk(logDirectory):
        for file in files:
            if file.__contains__("INFO") or file.__contains__("postgres") or file.__contains__("controller") and file[0] != ".":
                logFiles.append(os.path.join(root, file))
    return logFiles

def getTimeFromLog(line):
    if line[0] in ['I', 'W', 'E', 'F']:
        timeFromLogLine = line.split(' ')[0][1:] + ' ' + line.split(' ')[1][:5]
        timestamp = datetime.datetime.strptime(timeFromLogLine, '%m%d %H:%M')
    else:
        timeFromLogLine = line.split(' ')[0] + ' ' + line.split(' ')[1]
        timestamp = datetime.datetime.strptime(timeFromLogLine, '%Y-%m-%d %H:%M:%S.%f')
        timestamp = timestamp.strftime('%m%d %H:%M')
    return timestamp

def filterLogFilesByTime(logFile, startTime, endTime, skippedLogFileStartEndTimes, logFileStartEndTimes):
    if logFile.endswith('.gz'):
        try:
            logs = gzip.open(logFile, 'rt')
        except:
            print('Error opening file: ' + logFile)
            return True
    else:
        logs = open(logFile, 'r')
    try:
        # Read the first 10 lines
        for i in range(10):
            line = logs.readline()
            try:
                logStartsAt = getTimeFromLog(line)
                # Covert logStartsAt  to 'MMDD HH:MM'
                logStartsAt = datetime.datetime.strptime(logStartsAt, '%m%d %H:%M')
                break
            except:
                continue
        # Read the last line
        last_lines = deque(logs, 10)
        for line in reversed(last_lines):
            try:
                logEndsAt = getTimeFromLog(line)
                logEndsAt = datetime.datetime.strptime(logEndsAt, '%m%d %H:%M')
                break
            except Exception as e:
                continue
        # Replace year with current year for all the timestamps
        logStartsAt = logStartsAt.replace(year=datetime.datetime.now().year)
        logEndsAt = logEndsAt.replace(year=datetime.datetime.now().year)
        startTime = startTime.replace(year=datetime.datetime.now().year)
        endTime = endTime.replace(year=datetime.datetime.now().year)
        if logStartsAt > endTime or logEndsAt < startTime:
            logger.debug('Skipping file: ' + logFile + 'Starts at: ' + str(logStartsAt) + ' Ends at: ' + str(logEndsAt))
            # Add the log file to the dictionary with start and end time and type
            if 'postgres' in logFile:
                skippedLogFileStartEndTimes[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': 'postgresql'}
            elif 'yb-tserver' in logFile:
                skippedLogFileStartEndTimes[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': 'yb-tserver'}
            elif 'yb-master' in logFile:
                skippedLogFileStartEndTimes[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': 'yb-master'}
            return False
        else:
            logger.debug('Including file: ' + logFile + 'Starts at: ' + str(logStartsAt) + ' Ends at: ' + str(logEndsAt))
            if 'postgres' in logFile:
                logFileStartEndTimes[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': 'postgresql'}
            elif 'yb-tserver' in logFile:
                logFileStartEndTimes[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': 'yb-tserver'}
            elif 'yb-master' in logFile:
                logFileStartEndTimes[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': 'yb-master'}
            return True
    except Exception as e:
        logger.warning('Unable to determine start or end time for file: ' + logFile + 'Error' + str(e))
        if 'postgres' in logFile:
            skippedLogFileStartEndTimes[logFile] = {'start': 'Unable to determine', 'end': 'Unable to determine', 'type': 'postgresql'}
        elif 'yb-tserver' in logFile:
            skippedLogFileStartEndTimes[logFile] = {'start': 'Unable to determine', 'end': 'Unable to determine', 'type': 'yb-tserver'}
        elif 'yb-master' in logFile:
            skippedLogFileStartEndTimes[logFile] = {'start': 'Unable to determine', 'end': 'Unable to determine', 'type': 'yb-master'}
        return True
    finally:
        logs.close()

def createFileMetadata(logFileMetadata, logFile, logStartsAt, logEndsAt, logType):
    logFileMetadata[logFile] = {'start': logStartsAt, 'end': logEndsAt, 'type': logType}
    return logFileMetadata

def filterLogFilesByType(file_list, types):
    # Define type mappings to identify relevant log files
    type_mappings = {
        "pg": "postgresql",  # PostgreSQL logs
        "ts": "yb-tserver",  # TServer logs
        "ms": "yb-master"     # Master logs
    }
    
    # Get selected keywords from types
    selected_keywords = [type_mappings[t] for t in types if t in type_mappings]
    
    # Filter files containing the selected keywords
    filtered_files = []
    removed_files = []
    for file in file_list:
        if any(keyword in file for keyword in selected_keywords):
            filtered_files.append(file)
        else:
            removed_files.append(file)
            
    # Filter hidden files
    file_names = [os.path.basename(file) for file in filtered_files]
    filtered_files = [file for file in filtered_files if not file.startswith('.')]
    
    logger.debug(f"Included files: {filtered_files}")
    logger.debug(f"Removed files: {removed_files}")
    
    return filtered_files

def filterLogFilesByNode(file_list, nodes):
    # Filter files containing the selected nodes
    filtered_files = []
    removed_files = []
    for file in file_list:
        if any(node in file for node in nodes):
            filtered_files.append(file)
        else:
            removed_files.append(file)

    logger.debug(f"Included files: {filtered_files}")
    logger.debug(f"Removed files: {removed_files}")
    
    return filtered_files

if __name__ == '__main__':
    args = parser.parse_args()
    # Set up logging
    logger = logging.getLogger(__name__)
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO, format=log_format)
    if args.debug:
        logger.debug('Debug mode enabled')
    if args.start_time:
        startTime = datetime.datetime.strptime(args.start_time, '%m%d %H:%M')
    else:
        startTime = datetime.datetime.now() - datetime.timedelta(days=7)
    startTime = startTime.replace(year=datetime.datetime.now().year)
    print('Start time: ' + str(startTime))
    if args.end_time:
        endTime = datetime.datetime.strptime(args.end_time, '%m%d %H:%M')
    elif args.duration:
        endTime = startTime + parse_duration(args.duration)
    else:
        endTime = datetime.datetime.now()
    endTime = endTime.replace(year=datetime.datetime.now().year)
    print('End time: ' + str(endTime))
    logFiles = getLogFilesFromCurrentDir()
    if args.nodes:
        nodes = args.nodes.split(',')
        logFiles=filterLogFilesByNode(logFiles, nodes)
    if args.types:
        types = args.types.split(',')
        logFiles=filterLogFilesByType(logFiles, types)
    logger.debug('Log files found: ' + str(logFiles))
    logFilesForLnav = []
    # JSON to maintain start and end time of the log file
    skippedLogFileStartEndTimes = {}
    # JSON to maintain start and end time of the included log file
    logFileStartEndTimes = {}

    # Start the spinner in a separate thread
    done = False
    spinner_thread = threading.Thread(target=spinner)
    spinner_thread.start()
    for logFile in logFiles:
        if filterLogFilesByTime(logFile, startTime, endTime, skippedLogFileStartEndTimes, logFileStartEndTimes):
            logFilesForLnav.append(logFile)
    # Stop the spinner
    done = True
    spinner_thread.join()
    
    # Print the log files that are skipped
    SkippedFiles = []
    print('====================Skipped Files====================')
    for logFile in skippedLogFileStartEndTimes:
        SkippedFiles.append([logFile[-100:], skippedLogFileStartEndTimes[logFile]['type'], skippedLogFileStartEndTimes[logFile]['start'], skippedLogFileStartEndTimes[logFile]['end']])
    print(tabulate.tabulate(SkippedFiles, headers=['LogFile', 'Type', 'StartTime', 'EndTime'], tablefmt='simple_grid'))
    
    # Print the log files that are included
    IncludedFiles = []
    print('====================Included Files====================')
    for logFile in logFileStartEndTimes:
        IncludedFiles.append([logFile[-100:], logFileStartEndTimes[logFile]['type'], logFileStartEndTimes[logFile]['start'], logFileStartEndTimes[logFile]['end']])
    print(tabulate.tabulate(IncludedFiles, headers=['LogFile', 'Type', 'StartTime', 'EndTime'], tablefmt='simple_grid'))
    
    Command = []
    print('====================Command====================')
    if len(logFilesForLnav) > 0:
        Command.append('lnav')
        Command.extend(logFilesForLnav)
        # current_year = datetime.datetime.now().year
        if args.start_time:
            # Time in YYYY-MM-DD HH:MM:SS format
            # startTime = startTime.replace(year=current_year)
            Command.append("-c ':hide-lines-before " + startTime.strftime('%Y-%m-%d %H:%M:%S') + "'")
        if args.end_time or args.duration:
            # endTime = endTime.replace(year=current_year)
            Command.append("-c ':hide-lines-after " + endTime.strftime('%Y-%m-%d %H:%M:%S') + "'")
        print(' '.join(Command))
        try:
            print('')
            input('Press Enter to execute the command above or press Ctrl+C to exit')
            os.system(' '.join(Command))
        except KeyboardInterrupt:
            print('Exiting...')
            exit()
    else:
        print('No log files found for the given time range')