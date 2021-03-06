#---------------------------------------------------------------------------
# Copyright 2012 The Open Source Electronic Health Record Agent
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#---------------------------------------------------------------------------

## @package OSEHRAHelper
## OSEHRA test helper

'''
OSEHRAHelper provides classes that establish connections to VistA
and interaction methods such as write() and wait()

@copyright The Open Source Electronic Health Record Agent
@license http://www.apache.org/licenses/LICENSE-2.0
'''

import sys
import os
import telnetlib
import TestHelper
import time
import re
import logging
import csv
from ParseCSVforPackagePrefixes import FindPackagePrefixes

filedir = os.path.dirname(os.path.abspath(__file__))
pexpectdir = os.path.normpath(os.path.join(filedir, "../Pexpect"))
sys.path.append(pexpectdir)
try:
  import pexpect
  no_pexpect = None
except ImportError, no_pexpect:
  pass


#---------------------------------------------------------------------------
# Initial Global Variables to use over the course of connecting

# connection=False
# log =False

#---------------------------------------------------------------------------
class PROMPT(object):
  """Wait for a VISTA> prompt in current namespace."""

class ConnectMUMPS(object):

  def GetVistARoutines(self, vista_source_dir, test_results_dir, packagename):
    packages_csv_file = vista_source_dir + '/Packages.csv'

    packageprefix_sorted = FindPackagePrefixes(packagename, packages_csv_file)
    return self.PlatformDependRoutine(packageprefix_sorted, packagename, test_results_dir)

  def ClearExcludedRoutines(self, routine_set):
    routine_set_clean = []
    ROUTINE_EXTRACT_EXCLUDE_LIST = (
       "ZGO", "ZGI", "CHK2LEV", "CHKOP", "GENDASH", "GENOUT",
       "GETPASS", "GTMHELP", "GTMHLPLD", "LOADOP",
       "LOADVX", "MSG", "PINENTRY", "TTTGEN",
       "TTTSCAN", "NAME", "ZZRGUT.*", "ZZDGPTCO1",
       "ZZUT.*", "DMU.*"
    )
    routine_exclude_regex = re.compile('^(' + '|'.join(ROUTINE_EXTRACT_EXCLUDE_LIST) + ')$')
    for routine in routine_set:
      if routine == "T":
        continue
      elif re.match(routine_exclude_regex, routine) is None:
        routine_set_clean.append(routine)
    return routine_set_clean

  def ZN(self, namespace):
    self.wait('>')
    self.write('ZN "' + namespace + '"')
    self.namespace = namespace
    self.prompt = self.namespace + '>'

  def login(self, username, password):
    self.wait('Username:')
    self.write(username)
    self.wait('Password')
    self.write(password)

  def getenv(self, volume):
    self.write('D GETENV^%ZOSV W Y')
    if sys.platform == 'win32':
      match = self.wait_re([volume + ':[0-9A-Za-z-]+'], None)
      test = match[1].span()
      VistAboxvol = ''
      for i in range(test[0], test[1]):
        VistAboxvol = VistAboxvol + match[2][i]
      self.boxvol = VistAboxvol
    else:
      self.wait_re(volume + ':[0-9A-Za-z-]+', None)
      self.boxvol = self.connection.after

  def IEN(self, file, objectname):
    self.write('S DUZ=1 D Q^DI')
    self.wait('OPTION')
    self.write('5')
    self.wait('FILE:')
    self.write(file)
    self.wait(file + ' NAME')
    self.write(objectname + '\r')
    self.wait('CAPTIONED OUTPUT?')
    self.write('N')
    self.wait('PRINT FIELD')
    self.write('NUMBER\r')
    self.wait('Heading')
    self.write('')
    self.wait('DEVICE')
    if sys.platform == 'win32':
      self.write('\r')
      match = self.wait_re(['\r\n[0-9]+'], None)
      test = match[1].span()
      number = ''
      for i in range(test[0], test[1]):
        number = number + match[2][i]
      number = number.lstrip('\r\n')
      self.IENumber = number
    else:
      self.write('')
      self.wait_re(['\n[0-9]+'], None)
      number = self.connection.after
      number = number.lstrip('\r\n')
      self.IENumber = number
    self.write('')

class ConnectWinCache(ConnectMUMPS):
  def __init__(self, logfile, instance, namespace, location='127.0.0.1'):
    super(ConnectMUMPS, self).__init__()
    self.connection = telnetlib.Telnet(location, 23)
    if len(namespace) == 0:
      namespace = 'VISTA'
    self.namespace = namespace
    self.prompt = self.namespace + '>'
    self.log = file(logfile, 'w')
    self.type = 'cache'

  def write(self, command):
    self.connection.write(command + '\r')
    logging.debug('connection.write:' + command)

  def wait(self, command, tout=15):
    if command is PROMPT:
      command = self.namespace + '>'
    rbuf = self.connection.read_until(command, tout)
    if rbuf.find(command) == -1:
        self.log.write('ERROR: expected: ' + command + 'actual: ' + rbuf)
        logging.debug('ERROR: expected: ' + command + 'actual: ' + rbuf)
        raise TestHelper.TestError('ERROR: expected: ' + command + 'actual: ' + rbuf)
    else:
        self.log.write(rbuf)
        logging.debug(rbuf)
        return 1

  def wait_re(self, command, timeout=30):
    if command is PROMPT:
      command = self.prompt
    output = self.connection.expect(command, None)
    self.match = output[1]
    self.before = output[2]
    if output[0] == -1 and output[1] == None:
      raise Exception("Timed out")
    if output[2]:
      self.log.write(output[2])
      self.log.flush()
      return output

  def multiwait(self, options, tout=15):
    if isinstance(options, list):
      index = self.connection.expect(options, tout)
      if index == -1:
        logging.debug('ERROR: expected: ' + options)
        raise TestHelper.TestError('ERROR: expected: ' + options)
      self.log.write(index[2])
      return index[0]
    else:
      raise IndexError('Input to multiwait function is not a list')

  def startCoverage(self, routines=['*']):
    self.write('D ^%SYS.MONLBL')
    rval = self.multiwait(['Stop Monitor', 'Start Monitor'])
    if rval == 0:
        self.write('1')
        self.wait('Start Monitor')
        self.write('1')
    elif rval == 1:
        self.write('1')
    else:
        raise TestHelper.TestError('ERROR starting monitor, rbuf: ' + rval)
    for routine in routines:
        self.wait('Routine Name')
        self.write(routine)
    self.wait('Routine Name', tout=60)
    self.write('')
    self.wait('choice')
    self.write('2')
    self.wait('choice')
    self.write('1')
    self.wait('continue')
    self.write('\r')

  def stopCoverage(self, path, humanreadable='OFF'):
    newpath, filename = os.path.split(path)
    self.write('D ^%SYS.MONLBL')
    self.wait('choice')
    if humanreadable == 'ON':
      self.write('5')
      self.wait('summary')
      self.write('Y')
    else:
      self.write('6')
      self.wait('Routine number')
      self.write('*')
    self.wait('FileName')
    self.write(newpath + '/Coverage/' + filename.replace('.log', '.cmcov').replace('.txt', '.cmcov'))
    self.wait('continue')
    self.write('')
    self.wait('choice')
    self.write('1\r')

  def PlatformDependRoutine(self, packageprefix, packagename, test_results_dir):
    self.write('D ^%RD')
    self.wait('Routine')
    if packagename == "Uncategorized":
      self.write("*")
      self.wait("Routine")
    for prefix in packageprefix:
      self.write(prefix + '*')
      self.wait('Routine')
    self.write('')
    index = self.multiwait(['Long or Short form', self.prompt])
    if index == 1:
      return 0
    self.write('L')
    self.wait('last modified since date', 120)
    self.write('')
    self.wait('on or before date')
    self.write('')
    self.wait('Device')
    self.write(test_results_dir + '/' + packagename + '.txt')
    self.wait('Parameters')
    self.write('WNS')
    while True:
      index = self.multiwait(['overwrite it', self.prompt])
      if index == 0:
        self.write('')
        continue
      if index == 1:
        break
    routineset = []
    if os.path.exists(test_results_dir + '/' + packagename + '.txt'):
      routine_list = set(open(test_results_dir + '/' + packagename + '.txt', 'r').readlines())
      for routine in routine_list:
        REreturn = re.match("^[A-Z0-9]+", routine)
        if REreturn is not None:
          routineset.append(REreturn.group(0))
      return self.ClearExcludedRoutines(routineset)
    else:
      print "No Routines were written to" + test_results_dir + "/" + packagename + ".txt"
      return 0

class ConnectLinuxCache(ConnectMUMPS):
  def __init__(self, logfile, instance, namespace, location='127.0.0.1'):
    super(ConnectMUMPS, self).__init__()
    self.connection = pexpect.spawn('ccontrol session ' + instance + ' -U ' + namespace, timeout=None)
    if len(namespace) == 0:
      namespace = 'VISTA'
    self.namespace = namespace
    self.prompt = self.namespace + '>'
    self.connection.logfile_read = file(logfile, 'w')
    self.type = 'cache'

  def write(self, command):
    self.connection.send(command + '\r')

  def wait(self, command, tout=15):
    if command is PROMPT:
      command = self.namespace + '>'
    rbuf = self.connection.expect_exact(command, tout)
    if rbuf == -1:
        logging.debug('ERROR: expected: ' + command)
        raise TestHelper.TestError('ERROR: expected: ' + command)
    else:
        return 1

  def wait_re(self, command, timeout=15):
    if not timeout: timeout = -1
    self.connection.expect(command, timeout)

  def multiwait(self, options, tout=15):
    if isinstance(options, list):
      index = self.connection.expect(options, tout)
      if index == -1:
        logging.debug('ERROR: expected: ' + options)
        raise TestHelper.TestError('ERROR: expected: ' + options)
      self.connection.logfile_read.write(options[index])
      return index
    else:
      raise IndexError('Input to multiwait function is not a list')

  def startCoverage(self, routines=['*']):
    self.write('D ^%SYS.MONLBL')
    rval = self.multiwait(['Stop Monitor', 'Start Monitor'])
    if rval == 0:
        self.write('1')
        self.wait('Start Monitor')
        self.write('1')
    elif rval == 1:
        self.write('1')
    else:
        raise TestHelper.TestError('ERROR starting monitor, rbuf: ' + rval)
    for routine in routines:
        self.wait('Routine Name')
        self.write(routine)
    self.wait('Routine Name', tout=60)
    self.write('')
    self.wait('choice')
    self.write('2')
    self.wait('choice')
    self.write('1')
    self.wait('continue')
    self.write('\r')

  def stopCoverage(self, path, humanreadable='OFF'):
    newpath, filename = os.path.split(path)
    self.write('D ^%SYS.MONLBL')
    self.wait('choice')
    if humanreadable == 'ON':
      self.write('5')
      self.wait('summary')
      self.write('Y')
    else:
      self.write('6')
      self.wait('Routine number')
      self.write('*')
    self.wait('FileName')
    self.write(newpath + '/Coverage/' + filename.replace('.log', '.cmcov').replace('.txt', '.cmcov'))
    self.wait('continue')
    self.write('')
    self.wait('choice')
    self.write('1\r')

  def PlatformDependRoutine(self, packageprefix, packagename, test_results_dir):
    self.write('D ^%RD')
    self.wait('Routine')
    if packagename == "Uncategorized":
      self.write("*")
      self.wait("Routine")
    for prefix in packageprefix:
      self.write(prefix + '*')
      self.wait('Routine')
    self.write('')
    index = self.multiwait(['Long or Short form', self.prompt])
    if index == 1:
      return 0
    self.write('L')
    self.wait('last modified since date', 120)
    self.write('')
    self.wait('on or before date')
    self.write('')
    self.wait('Device')
    self.write(test_results_dir + '/' + packagename + '.txt')
    self.wait('Parameters')
    self.write('WNS')
    while True:
      index = self.multiwait(['overwrite it', self.prompt])
      if index == 0:
        self.write('')
        continue
      if index == 1:
        break
    routineset = []
    if os.path.exists(test_results_dir + '/' + packagename + '.txt'):
      routine_list = set(open(test_results_dir + '/' + packagename + '.txt', 'r').readlines())
      for routine in routine_list:
        REreturn = re.match("^[A-Z0-9]+", routine)
        if REreturn is not None:
          routineset.append(REreturn.group(0))
      return self.ClearExcludedRoutines(routineset)
    else:
      print "No Routines were written to" + test_results_dir + "/" + packagename + ".txt"
      return 0

class ConnectLinuxGTM(ConnectMUMPS):
  def __init__(self, logfile, instance, namespace, location='127.0.0.1'):
    super(ConnectMUMPS, self).__init__()
    self.connection = pexpect.spawn('gtm', timeout=None)
    if len(namespace) == 0:
        self.prompt = os.getenv("gtm_prompt")
        if self.prompt == None:
          self.prompt = "GTM>"
    self.connection.logfile_read = file(logfile, 'w')
    self.type = 'GTM'

  def write(self, command):
    self.connection.send(command + '\r')
    logging.debug('WRITE: ' + command)

  def wait(self, command, tout=15):
    if command is PROMPT:
      command = self.prompt
    rbuf = self.connection.expect_exact(command, tout)
    logging.debug('RECEIVED: ' + command)
    if rbuf == -1:
        logging.debug('ERROR: expected: ' + command)
        raise TestHelper.TestError('ERROR: expected: ' + command)
    else:
        return 1

  def wait_re(self, command, timeout=None):
    if not timeout: timeout = -1
    self.connection.expect(command, timeout)

  def multiwait(self, options, tout=15):
    if isinstance(options, list):
      index = self.connection.expect(options, tout)
      if index == -1:
        logging.debug('ERROR: expected: ' + options)
        raise TestHelper.TestError('ERROR: expected: ' + options)
      self.connection.logfile_read.write(options[index])
      return index
    else:
      raise IndexError('Input to multiwait function is not a list')

  def startCoverage(self, routines=['*']):
    self.write('K ^ZZCOVERAGE VIEW "TRACE":1:"^ZZCOVERAGE"')

  def stopCoverage(self, path, humanreadable='OFF'):
    path, filename = os.path.split(path)
    self.write('VIEW "TRACE":0:"^ZZCOVERAGE"')
    self.wait(PROMPT)
    self.write('D ^%GO')
    self.wait('Global')
    self.write('ZZCOVERAGE')
    self.wait('Global')
    self.write('')
    self.wait('Label:')
    self.write('')
    self.wait('Format')
    self.write('ZWR')
    self.wait('device')
    self.write(path + '/Coverage/' + filename.replace('.log', '.mcov').replace('.txt', '.mcov'))

  def PlatformDependRoutine(self, packageprefix, packagename, test_results_dir):
    self.write('S %ZRSET=1 D ^%RSEL')
    self.wait('Routine')
    if packagename == "Uncategorized":
      self.write("*")
      self.wait("Routine")
    for prefix in packageprefix:
      self.write(prefix + '*')
      self.wait('Routine')
    self.write('')
    self.wait(PROMPT)
    self.write('D ^%GO')
    self.wait('Global ^')
    self.write('%RSET')
    self.wait('Global ^')
    self.write('')
    self.wait('Header Label')
    self.write('')
    self.wait('Output Format')
    self.write('ZWR')
    self.wait('Output device')
    self.write(test_results_dir + '/' + packagename + '.txt')
    self.wait(PROMPT)
    self.write('K ^%RSET K %ZRSET')
    self.wait(PROMPT)
    routineset = []
    if os.path.exists(test_results_dir + '/' + packagename + '.txt'):
      routine_list = set(open(test_results_dir + '/' + packagename + '.txt', 'r').readlines())
      if packagename == "Uncategorized":
        for routine in routine_list:
          REreturn = re.search('"[A-Z0-9]+"', routine)
          if REreturn is not None:
            routineset.append(REreturn.group(0).replace('"', ''))
      else:
        for prefix in packageprefix:
          for routine in routine_list:
            REreturn = re.search(prefix + '[A-Z0-9]+', routine)
            if REreturn is not None:
              routineset.append(REreturn.group(0))
      return self.ClearExcludedRoutines(routineset)
    else:
      print "No Routines were written to" + test_results_dir + "/" + packagename + ".txt"
      return 0


def ConnectToMUMPS(logfile, instance='CACHE', namespace='VISTA', location='127.0.0.1'):

    # self.namespace = namespace
    # self.location = location
    # print "You are using " + sys.platform
    if sys.platform == 'win32':
      return ConnectWinCache(logfile, instance, namespace, location)
    elif sys.platform == 'linux2':
      if no_pexpect:
        raise no_pexpect
      try:
        return ConnectLinuxCache(logfile, instance, namespace, location)
      except pexpect.ExceptionPexpect, no_cache:
        pass
      try:
        return ConnectLinuxGTM(logfile, instance, namespace, location)
      except pexpect.ExceptionPexpect, no_gtm:
         if (no_cache and no_gtm):
           raise "Cannot find a MUMPS instance"
