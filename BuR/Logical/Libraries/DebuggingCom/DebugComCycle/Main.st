
PROGRAM _INIT
	DebuggingCom.b_init := TRUE;
	DebuggingCom.Internal.Cyclic.Instance := ADR(DebuggingCom);
	DebuggingCom.AddString.Instance := ADR(DebuggingCom);
	DebuggingCom.AddData.Instance := ADR(DebuggingCom);
END_PROGRAM

PROGRAM _CYCLIC
	
	DebuggingCom.Internal.Cyclic();

END_PROGRAM

PROGRAM _EXIT

	 
END_PROGRAM

