#-----------------------------------------------------------------------------
#------ SET UP UNIT TEST ENV -----#
#-----------------------------------------------------------------------------
set(VENDER_NAME "GTM")

#-----------------------------------------------------------------------------#
##### SECTION TO SETUP THE REFRESH OF THE DATABASE #####
#-----------------------------------------------------------------------------#
if(TEST_VISTA_FRESH)
  #Finds the scripting program for the Linux Based system
  set(TEST_VISTA_SETUP_UCI_NAME "PLA" CACHE STRING "GTM  UCI to store VistA")
  set(TEST_VISTA_SETUP_VOLUME_SET "PLA" CACHE STRING "Volume Set for new Vista Instance")

  #Creates variables for the routines and globals directorys within GT.M
  set(TEST_VISTA_FRESH_GTM_ROUTINE_DIR "" CACHE PATH
    "Directory where OSEHRA routines should be imported while setting up a fresh VistA instance. (NOTE: Path must be in the 'gtmroutines' environment variable)")
  if(NOT TEST_VISTA_FRESH_GTM_ROUTINE_DIR AND TEST_VISTA_GTM_ROUTINE_DIR)
    set(TEST_VISTA_FRESH_GTM_ROUTINE_DIR ${TEST_VISTA_GTM_ROUTINE_DIR})
  endif()
  set(TEST_VISTA_FRESH_GTM_GLOBALS_DAT "" CACHE FILEPATH " Path to the GT.M database.dat")

  list(APPEND freshinfo TEST_VISTA_SETUP_UCI_NAME)
  list(APPEND freshinfo TEST_VISTA_SETUP_VOLUME_SET)
  list(APPEND freshinfo TEST_VISTA_FRESH_GTM_ROUTINE_DIR)
  list(APPEND freshinfo TEST_VISTA_FRESH_GTM_GLOBALS_DAT)
endif()

#-----------------------------------------------------------------------------#
##### SECTION TO RUN UNIT TESTING #####
#-----------------------------------------------------------------------------#
if(TEST_VISTA_MUNIT)
  execute_process(
    COMMAND ${PYTHON_EXECUTABLE} ${VISTA_SOURCE_DIR}/Testing/Python/ParseGTMRoutines.py
    OUTPUT_VARIABLE GTM_ROUTINE_DIRS
    )
  string(STRIP "${GTM_ROUTINE_DIRS}" GTM_ROUTINE_DIRS)
  set(GTM_SOURCE_DIR ${GTM_ROUTINE_DIRS} CACHE STRING
      "List of directories that contain GT.M source routines obtained
by parsing the 'gtmroutines' environment variable")
  list(GET GTM_SOURCE_DIR 0 firstPath)
  set(TEST_VISTA_GTM_ROUTINE_DIR ${firstPath} CACHE STRING
      "Directory where OSEHRA GT.M routines are imported.
MUnit test routines will be imported here.
To modify the list, edit GTM_SOURCE_DIR")
  set_property(CACHE TEST_VISTA_GTM_ROUTINE_DIR PROPERTY STRINGS ${GTM_SOURCE_DIR})
  set(RoutineImportDir ${TEST_VISTA_GTM_ROUTINE_DIR})
endif()

#-----------------------------------------------------------------------------#
##### SECTION TO RUN GTMROUTINES VARIABLE PARSING TEST #####
#-----------------------------------------------------------------------------#
if(GTM_DIST)
  configure_file("${VISTA_SOURCE_DIR}/Testing/Python/ParseGTMRoutinesTest.py.in"
                 "${VISTA_BINARY_DIR}/Testing/Python/ParseGTMRoutinesTest.py")
  add_test(PYTHON_GTMRoutinesParser ${PYTHON_EXECUTABLE}
           ${VISTA_BINARY_DIR}/Testing/Python/ParseGTMRoutinesTest.py)
  set_tests_properties(PYTHON_GTMRoutinesParser
                       PROPERTIES FAIL_REGULAR_EXPRESSION "FAILED")
endif()

