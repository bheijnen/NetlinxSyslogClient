PROGRAM_NAME='Main'
(***********************************************************)
(***********************************************************)
(*  FILE_LAST_MODIFIED_ON: 04/05/2006  AT: 09:00:25        *)
(***********************************************************)
(* System Type : NetLinx                                   *)
(***********************************************************)
(* REV HISTORY:                                            *)
(***********************************************************)
(*
    $History: $
*)
(***********************************************************)
(*          DEVICE NUMBER DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_DEVICE
dvSyslog		=     0: 3:0
vdvSyslog		= 33001: 1:0

(***********************************************************)
(*               CONSTANT DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_CONSTANT
/*	SEVERITY CONSTANTS	*/
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

/*	FACILITY CONSTANTS	*/
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

CHAR acServerAddress[] = '192.168.86.33'


(***********************************************************)
(*              DATA TYPE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_TYPE

(***********************************************************)
(*               VARIABLE DEFINITIONS GO BELOW             *)
(***********************************************************)
DEFINE_VARIABLE

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
DEFINE_MODULE 'Syslog_Client_dr1_0_0' Syslog_Client_dr1_0_0(vdvSyslog, dvSyslog)

(***********************************************************)
(*                STARTUP CODE GOES BELOW                  *)
(***********************************************************)
DEFINE_START

(***********************************************************)
(*                THE EVENTS GO BELOW                      *)
(***********************************************************)
DEFINE_EVENT
DATA_EVENT[vdvSyslog]
{
    ONLINE:
    {
	SET_LOG_LEVEL(AMX_DEBUG)
	
	SEND_COMMAND DATA.DEVICE,"'PROPERTY-Facility:Kernel'"
	SEND_COMMAND DATA.DEVICE,"'PROPERTY-Severity:Emergency'"
	SEND_COMMAND DATA.DEVICE,"'PROPERTY-IpAddress:',acServerAddress"
	
	//SEND_COMMAND DATA.DEVICE,"'PASSTHRU-bladiebla'"
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

