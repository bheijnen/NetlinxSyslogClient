MODULE_NAME='Syslog_Client_dr1_0_0' (DEV vdvVirtual, DEV dvDevice)
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/04/2006  AT: 11:33:16        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
	http://tools.ietf.org/html/rfc3164
	http://sourceforge.net/projects/syslog-server/
	http://www.monitorware.com/common/en/articles/syslog-described.php
    
*)    
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE
dvMaster = 0:1:0

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
TIMELINE_ID_1				=	    1

MAX_PACKET_LENGTH			=	 1024
MAX_TIMESTAMP_LENGTH			=	   15
MAX_PRIORITY_LENGTH			=	    5
SYSLOG_PORT				=	  514

// IP PROPERTIES
SLONG IP_STATUS_UNKNOWN			=          -1
MAX_IPADDRESS_LENGTH			=	   15
MAX_HOSTNAME_LENGTH			=	  255

/*	COMMAND CONSTANTS	*/
MAX_COMMAND_LENGTH			=	   30
CMD_SET_INIT				=	    1
CMD_SET_PROPERTY			=	    2
CMD_GET_PROPERTY			=	    3
CMD_RESET_PACKETCOUNT			=	    4
CMD_GET_PACKETCOUNT			=	    5
CMD_PASSTHRU				=	    6
CHAR acCommands[][MAX_COMMAND_LENGTH]	= { 'INIT', 'PROPERTY', '?PROPERTY', '?COUNT', 'COUNT', 'PASSTHRU' }

// MODULE PROPERTIES
MAX_PROPNAME_LENGTH			=	   30
MAX_PROPVAL_LENGTH			=	   30
PROPERTY_HOSTNAME			=	    1
PROPERTY_IPADDRESS			=	    2
PROPERTY_FACILITY			=	    3
PROPERTY_SEVERITY			=	    4
CHAR acProperties[][MAX_PROPNAME_LENGTH]= { 'hostname', 'ipaddress', 'facility', 'severity'}

/*	PRIORITY CONSTANTS	*/
MAX_SEVERITY_NAME_LENGTH		=	   16
SEVERITY_EMERGENCY			=	    1
SEVERITY_ALERT				=	    2
SEVERITY_CRITICAL			=	    3
SEVERITY_ERROR				=	    4
SEVERITY_WARNING			=	    5
SEVERITY_NOTICE				=	    6
SEVERITY_INFO				=	    7
SEVERITY_DEBUG				=	    8
CHAR acSeverityNames[][MAX_SEVERITY_NAME_LENGTH] = { 'emergency', 'alert', 'critical', 'error', 'warning', 'notice', 'info', 'debug' }

MAX_FACILITY_NAME_LENGTH		=	   16
FACILITY_KERNEL				=	    1
FACILITY_USER				=	    2
FACILITY_MAIL				=	    3
FACILITY_DEAMON				=	    4
FACILITY_AUTHENTICATION			=	    5
FACILITY_SYSLOG				=	    6
FACILITY_LINEPRINTER			=	    7
FACILITY_NETWORK_NEWS			=	    8
FACILITY_UUCP				=	    9
FACILITY_CLOCKDEAMON			=	   10
FACILITY_SECURITY_A			=	   11
FACILITY_FTPDAEMON			=	   12
FACILITY_NTP				=	   13
FACILITY_LOGAUDIT			=	   14
FACILITY_LOGALERT			=	   15
FACILITY_CLOCKDAEMON_A			=	   16
FACILITY_LOCAL0				=	   17
FACILITY_LOCAL1				=	   18
FACILITY_LOCAL2				=	   19
FACILITY_LOCAL3				=	   20
FACILITY_LOCAL4				=	   21
FACILITY_LOCAL5				=	   22
FACILITY_LOCAL6				=	   23
FACILITY_LOCAL7				=	   24
CHAR acFacilityNames[][MAX_FACILITY_NAME_LENGTH] = { 'kernel', 'user', 'mail', 'deamon', 'auth', 'syslog', 'lineprinter', 'netwerknews', 'uucp', 'clockdeamon', 'security', 'ftpdeamon', 
							'ntp', 'logaudit', 'logalert', 'clockdeamon_a', 'local0', 'local1', 'local2', 'local3', 'local4', 'local5', 'local6', 'local7' }

CHAR acMonthNames[][3] = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'}


#INCLUDE 'SNAPI.axi'
(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE
STRUCTURE _uIpDevice
{
    CHAR acHostname[MAX_HOSTNAME_LENGTH]	// what is the maximum length of a hostname ???
    CHAR acIpAddress[MAX_IPADDRESS_LENGTH]
}

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE
VOLATILE DEV_INFO_STRUCT uDeviceInfo
VOLATILE IP_ADDRESS_STRUCT uIpAddress
VOLATILE _uIpDevice uServer

VOLATILE CHAR acIpAddress[MAX_IPADDRESS_LENGTH]
VOLATILE CHAR acHostname[MAX_HOSTNAME_LENGTH]
VOLATILE CHAR acSyslogServerAddress[MAX_HOSTNAME_LENGTH]
VOLATILE LONG lTimeArray[] = 	  {0,5000}
VOLATILE SLONG slIpConnection

VOLATILE LONG lPacketCounter
VOLATILE INTEGER nPacketSize

PERSISTENT INTEGER nSeverity
PERSISTENT INTEGER nFacility

(***********************************************************)
(*               LATCHING DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_LATCHING

(***********************************************************)
(*       MUTUALLY EXCLUSIVE DEFINITIONS GO BELOW           *)
(***********************************************************)
DEFINE_MUTUALLY_EXCLUSIVE

(***********************************************************)
(*        SUBROUTINE/FUNCTION DEFINITIONS GO BELOW         *)
(***********************************************************)
(* EXAMPLE: DEFINE_FUNCTION <RETURN_TYPE> <NAME> (<PARAMETERS>) *)
(* EXAMPLE: DEFINE_CALL '<NAME>' (<PARAMETERS>) *)
DEFINE_FUNCTION fnParseCommand(INTEGER nCmdIdx, CHAR acValue[]) {
    SWITCH(nCmdIdx) {
	CASE CMD_SET_INIT:
	    IP_CLIENT_CLOSE(dvDevice.PORT)
	    BREAK;
	CASE CMD_SET_PROPERTY:
	    fnParseSetProperty(acValue)
	    BREAK;
	CASE CMD_GET_PROPERTY:
	    fnParseGetProperty(acValue)
	    BREAK;
	CASE CMD_RESET_PACKETCOUNT:
	    fnResetPacketCounter()
	    BREAK;
	CASE CMD_GET_PACKETCOUNT:
	    fnGetPacketCounter()
	    BREAK;
	CASE CMD_PASSTHRU:
	    fnSendSyslogMessage(acValue)
	    BREAK;
	DEFAULT:
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnParseCommand(',ITOA(nCmdIdx),') unhandled'")
	    BREAK;
    }
}

DEFINE_FUNCTION fnSendSyslogMessage(CHAR acData[])
{
    STACK_VAR INTEGER nPriority
    STACK_VAR CHAR acPriority[MAX_TIMESTAMP_LENGTH]
    STACK_VAR CHAR acTimeStamp[MAX_TIMESTAMP_LENGTH]
    STACK_VAR CHAR acHostname[MAX_HOSTNAME_LENGTH]
    STACK_VAR CHAR acUdpPacket[MAX_PACKET_LENGTH+12]
    
    nPriority = (nFacility*8) + nSeverity
    acPriority = "'<',FORMAT('%03d',nPriority),'>'"
    acTimeStamp = "acMonthNames[TYPE_CAST(DATE_TO_MONTH(LDATE))],' ',FORMAT('% 2d',DATE_TO_DAY(LDATE)), ' ', TIME"
    IF(LENGTH_STRING(uIpAddress.HOSTNAME) > 0) {
	acHostname = "uIpAddress.HOSTNAME"
    }
    ELSE {
	acHostname = "uIpAddress.IPADDRESS"
    }
    
    acUdpPacket = "acPriority,acTimeStamp,' ',acHostname,' ',acData"    
    nPacketSize = LENGTH_STRING(acUdpPacket)
    IF(nPacketSize <= MAX_PACKET_LENGTH) {
	AMX_LOG(AMX_DEBUG, "'mdl ',__FILE__,': ',acUdpPacket")
    }
    ELSE {
	// acUdppacket is max 1024+12 especially to see this notification
	AMX_LOG(AMX_ERROR, "'mdl ',__FILE__,': exceeding maximum packetlength for syslog message: ', ITOA(nPacketSize), ' resizing to 1024 bytes'")
	SET_LENGTH_STRING(acUdpPacket, MAX_PACKET_LENGTH)
    }
    
    // send the actual syslog packet
    SEND_STRING dvDevice,"acUdpPacket"
    lPacketCounter++
}
    DEFINE_FUNCTION fnParseSetProperty(CHAR acPropertyString[])
{
    STACK_VAR CHAR acPropertyName[MAX_PROPNAME_LENGTH]
    STACK_VAR CHAR acPropertyValue[MAX_PROPVAL_LENGTH]
    STACK_VAR INTEGER nIdx
    
    acPropertyName = REMOVE_STRING(acPropertyString,':', 1)
    SET_LENGTH_STRING(acPropertyName, LENGTH_STRING(acPropertyName)-1)
    acPropertyName = LOWER_STRING(acPropertyName)
    acPropertyValue = acPropertyString
    
    FOR(nIdx = 1; nIdx <= LENGTH_ARRAY(acProperties); nIdx++) {
	IF(acProperties[nIdx] == acPropertyName) {
	    BREAK;
	}
    }
    
    SWITCH(nIdx) {
	CASE PROPERTY_HOSTNAME:
	    IF(fnSetPropertyHostname(acPropertyValue)) {
		SEND_STRING vdvVirtual,"'invalid hostname'"
	    }
	    BREAK;
	CASE PROPERTY_IPADDRESS:
	    IF(fnSetPropertyIpAddress(acPropertyValue)) {
		SEND_STRING vdvVirtual,"'invalid ip address'"
	    }
	    BREAK;
	CASE PROPERTY_FACILITY:
	    IF(fnSetPropertyFacility(acPropertyValue)) {
		SEND_STRING vdvVirtual,"'invalid facility'"
	    }
	    BREAK;
	CASE PROPERTY_SEVERITY:
	    IF(fnSetPropertySeverity(acPropertyValue)) {
		SEND_STRING vdvVirtual,"'invalid severity'"
	    }
	    BREAK;
	DEFAULT:
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnParseSetProperty(',acPropertyString,') unhandled'")
	    BREAK;
    }
}
	DEFINE_FUNCTION INTEGER fnSetPropertyHostname(CHAR acHostname[])
{
    STACK_VAR INTEGER nResult

    IF(LENGTH_STRING(acHostname) > 0 && LENGTH_STRING(acHostname) <= MAX_HOSTNAME_LENGTH) {
	// what character would be allowed in a hostname????
	IF(FIND_STRING(acHostname,' ', 1)) {
	    // no spaces allowed in hostname
	    nResult = 2
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyHostname(',acHostname,') invalid hostname: can`t contain spaces'")
	}
	ELSE {
	    // store ip adress
	    uServer.acHostname = acHostname
	    
	    // clear ip address
	    uServer.acIpAddress = ''
	    
	    // reinit connection with new ip address
	    IF([vdvVirtual, DEVICE_COMMUNICATING] == TRUE) {
		AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyHostname(',acHostname,') changed, action:`performing required reinitialization`'")
		IP_CLIENT_CLOSE(dvDevice.PORT)
	    }
	}
    }
    ELSE {
	// length boundary invalid
	nResult = 1
	AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyHostname(',acHostname,') invalid length'")
    }
    
    RETURN nResult
}
	DEFINE_FUNCTION INTEGER fnSetPropertyIpAddress(CHAR acIpAddress[])
{
    STACK_VAR INTEGER nResult
    STACK_VAR INTEGER nIdx
    STACK_VAR INTEGER nField[4]
    STACK_VAR CHAR acNewIpAddress[MAX_IPADDRESS_LENGTH]

    acNewIpAddress = acIpAddress
    IF(LENGTH_STRING(acIpAddress) > 0) {
	IF(FIND_STRING(acIpAddress,'.',1)) {
	    nField[1] = ATOI(REMOVE_STRING(acIpAddress,'.',1))
	    IF(FIND_STRING(acIpAddress,'.',1)) {
		nField[2] = ATOI(REMOVE_STRING(acIpAddress,'.',1))
		IF(FIND_STRING(acIpAddress,'.',1)) {
		    nField[3] = ATOI(REMOVE_STRING(acIpAddress,'.',1))
		    nField[4] = ATOI(acIpAddress)
		}
	    }
	}
	
	FOR(nIdx = 1; nIdx <= 4; nIdx++) {
	    IF(nField[nIdx] > 254) {
		BREAK;
	    }
	}
	
	IF(nIdx == 5) {
	    // store ip adress
	    uServer.acIpAddress = acNewIpAddress
	    
	    // clear ip hostname
	    uServer.acHostname = ''
	    
	    // reinit connection with new ip address
	    IF([vdvVirtual, DEVICE_COMMUNICATING] == TRUE) {
		AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyIpAddress(',acNewIpAddress,') changed, action:`performing required reinitialization`'")
		IP_CLIENT_CLOSE(dvDevice.PORT)
	    }
	}
	ELSE {
	    // one or more fields not within limits
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyIpAddress(',acNewIpAddress,') one or more fields not within limits'")
	    nResult = 2
	}
    }
    ELSE {
	// no length
	AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyIpAddress(',acNewIpAddress,') invalid length'")
	nResult = 1
    }
    
    RETURN nResult
}
	DEFINE_FUNCTION INTEGER fnSetPropertyFacility(CHAR acFacilityName[])
{
    STACK_VAR INTEGER nIdx
    STACK_VAR INTEGER nResult    
    STACK_VAR INTEGER nPropertyFacility
    
    acFacilityName = LOWER_STRING(acFacilityName)
    FOR(nIdx = 1; nIdx <= LENGTH_ARRAY(acFacilityNames); nIdx++) {
	IF(acFacilityNames[nIdx] == acFacilityName) {
	    BREAK;
	}
    }
    
    SWITCH(nIdx) {
	CASE FACILITY_KERNEL:
	CASE FACILITY_USER:
	CASE FACILITY_MAIL:
	CASE FACILITY_DEAMON:
	CASE FACILITY_AUTHENTICATION:
	CASE FACILITY_SYSLOG:
	CASE FACILITY_LINEPRINTER:
	CASE FACILITY_NETWORK_NEWS:
	CASE FACILITY_UUCP:
	CASE FACILITY_CLOCKDEAMON:
	CASE FACILITY_SECURITY_A:
	CASE FACILITY_FTPDAEMON:
	CASE FACILITY_NTP:
	CASE FACILITY_LOGAUDIT:
	CASE FACILITY_LOGALERT:
	CASE FACILITY_CLOCKDAEMON_A:
	CASE FACILITY_LOCAL0:
	CASE FACILITY_LOCAL1:
	CASE FACILITY_LOCAL2:
	CASE FACILITY_LOCAL3:
	CASE FACILITY_LOCAL4:
	CASE FACILITY_LOCAL5:
	CASE FACILITY_LOCAL6:
	CASE FACILITY_LOCAL7:
	    nFacility = nIdx - 1	// syslog idx starts at 0
	    BREAK;
	DEFAULT:
	    // invalid severity
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertyFacility(',acFacilityName,') invalid facilityname'")
	    nResult = 1
	    BREAK;
    }
    
    RETURN nResult
}
	DEFINE_FUNCTION INTEGER fnSetPropertySeverity(CHAR acSeverityName[])
{
    STACK_VAR INTEGER nResult
    STACK_VAR INTEGER nIdx
    
    acSeverityName = LOWER_STRING(acSeverityName)
    FOR(nIdx = 1; nIdx <= LENGTH_ARRAY(acSeverityNames); nIdx++) {
	IF(acSeverityNames[nIdx] == acSeverityName) {
	    BREAK;
	}
    }
    
    SWITCH(nIdx) {
	CASE SEVERITY_EMERGENCY:
	CASE SEVERITY_ALERT:
	CASE SEVERITY_CRITICAL:
	CASE SEVERITY_ERROR:
	CASE SEVERITY_WARNING:
	CASE SEVERITY_NOTICE:
	CASE SEVERITY_INFO:
	CASE SEVERITY_DEBUG:
	    nSeverity = nIdx - 1	// syslog idx starts at 0
	    BREAK;
	DEFAULT:
	    // invalid severity
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnSetPropertySeverity(',acSeverityName,') invalid severityname'")
	    nResult = 1
	    BREAK;
    }
    
    RETURN nResult
}
    DEFINE_FUNCTION fnParseGetProperty(CHAR acPropertyString[])
{
    STACK_VAR CHAR acPropertyName[MAX_PROPNAME_LENGTH]
    STACK_VAR CHAR acPropertyValue[MAX_PROPVAL_LENGTH]
    STACK_VAR INTEGER nIdx
    
    acPropertyName = REMOVE_STRING(acPropertyString,':', 1)
    SET_LENGTH_STRING(acPropertyName, LENGTH_STRING(acPropertyName)-1)
    acPropertyName = LOWER_STRING(acPropertyName)
    acPropertyValue = acPropertyString
    
    FOR(nIdx = 1; nIdx <= LENGTH_ARRAY(acProperties); nIdx++) {
	IF(acProperties[nIdx] == acPropertyName) {
	    BREAK;
	}
    }
    
    SWITCH(nIdx) {
	CASE PROPERTY_HOSTNAME:
	    SEND_STRING vdvVirtual,"'PROPERTY-',acPropertyName,':',uServer.acHostname"
	    BREAK;
	CASE PROPERTY_IPADDRESS:
	    SEND_STRING vdvVirtual,"'PROPERTY-',acPropertyName,':',uServer.acIpAddress"
	    BREAK;
	DEFAULT:
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': fnParseGetProperty(',acPropertyString,') unhandled'")
	    BREAK;
    }
}
    DEFINE_FUNCTION fnResetPacketCounter()
{
    AMX_LOG(AMX_DEBUG,"'mdl ',__FILE__,': fnResetPacketCounter() performed'")
    lPacketCounter = 0
}
    DEFINE_FUNCTION fnGetPacketCounter()
{
    SEND_STRING vdvVirtual,"'COUNT-',ITOA(lPacketCounter)"
}
(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
DATA_EVENT[dvMaster]
{
    ONLINE:
    {
	DEVICE_INFO(dvMaster, uDeviceInfo)
	GET_IP_ADDRESS(dvMaster, uIpAddress)
    }
}

DATA_EVENT[vdvVirtual]
{
    ONLINE:
    {
	slIpConnection = IP_STATUS_UNKNOWN
	TIMELINE_CREATE(TIMELINE_ID_1, lTimeArray, LENGTH_ARRAY(lTimeArray), TIMELINE_ABSOLUTE, TIMELINE_REPEAT)    
    }
    COMMAND:
    {
	// DATA.TEXT is max 2000 bytes where as MAX_PACKET_LENGTH = 1024, so this is safe....
	STACK_VAR CHAR acCommand[MAX_COMMAND_LENGTH]
	STACK_VAR INTEGER nIdx
	
	// get CMD
	IF(FIND_STRING(DATA.TEXT,'?',1)) {
	    acCommand = DATA.TEXT
	}
	ELSE IF(FIND_STRING(DATA.TEXT,'-',1)) {
	    acCommand = REMOVE_STRING(DATA.TEXT,'-',1)
	    SET_LENGTH_STRING(acCommand, LENGTH_STRING(acCommand)-1)
	}
	
	// lookup and execute
	FOR(nIdx = 1; nIdx <= LENGTH_ARRAY(acCommands); nIdx++) {
	    IF(FIND_STRING(acCommands[nIdx],"acCommand", 1)) {
		fnParseCommand(nIdx, DATA.TEXT)
		BREAK;
	    }
	}
	
	IF(nIdx > LENGTH_ARRAY(acCommands)) {
	    AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': command (',acCommand,') unhandled'")
	}
	
	CLEAR_BUFFER DATA.TEXT
    }
}

DATA_EVENT[dvDevice]
{
    ONLINE:
    {
	ON[vdvVirtual, DEVICE_COMMUNICATING]
	AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': dvSyslog online'")
	fnSendSyslogMessage('Start udp syslog messaging')
    }
    ONERROR:
    {
	AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': dvSyslog onerror (', ITOA(DATA.NUMBER),')'")
	slIpConnection = TYPE_CAST(DATA.NUMBER)
    }
    OFFLINE:
    {
	slIpConnection = IP_STATUS_UNKNOWN
	OFF[vdvVirtual, DEVICE_COMMUNICATING]
	AMX_LOG(AMX_ERROR,"'mdl ',__FILE__,': dvSyslog offline'")
    }
}

TIMELINE_EVENT[TIMELINE_ID_1]
{
    SWITCH(TIMELINE.SEQUENCE) {
	CASE 1:
	    BREAK;
	CASE 2:
	    IF(LENGTH_STRING(uServer.acHostname)) {
		acSyslogServerAddress = uServer.acHostname
	    }
	    ELSE IF(LENGTH_STRING(uServer.acIpAddress)) {
		acSyslogServerAddress = uServer.acIpAddress
	    }
	    IF(LENGTH_STRING(acSyslogServerAddress)) {
		// validate ip address and port
		IF(slIpConnection) {
		    // only open if not already online and returned an error
		    slIpConnection = IP_CLIENT_OPEN(dvDevice.PORT, acSyslogServerAddress, SYSLOG_PORT, IP_UDP)
		}
	    }
	    BREAK;
    }
}

(***********************************************************)
(*            THE ACTUAL PROGRAM GOES BELOW                *)
(***********************************************************)
DEFINE_PROGRAM

(***********************************************************)
(*                     END OF PROGRAM                      *)
(*        DO NOT PUT ANY CODE BELOW THIS COMMENT           *)
(***********************************************************)
