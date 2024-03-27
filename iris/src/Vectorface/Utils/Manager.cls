Class Vectorface.Utils.Manager Extends %RegisteredObject
{
    /// Description
    ClassMethod CreateTable() As %Status
    {
        Set sc = $$$OK
        
        set sqlCreatePerson = "CREATE TABLE Vectorface_Data.Person (name VARCHAR(50), description VARCHAR(1000), photo VECTOR(DECIMAL, 128))"
        set statementCreatePerson = ##class(%SQL.Statement).%New()
        set statusCreatePerson = statementCreatePerson.%Prepare(sqlCreatePerson)
        if ($$$ISOK(statusCreatePerson)) {
            set resultSetCreatePerson = statementCreatePerson.%Execute()
        }
        Return sc
    }
}