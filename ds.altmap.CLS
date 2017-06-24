/// create additional databases 
/// and globals projections for current namespace
/// See: http://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=D2IMP_ch_setup#D2IMP_setup_globals_alt
Class ds.altmap [ Abstract ] {
ClassMethod install() {
 
	// fact tables and their indices	
	// When you initially build the cube, you might disable journaling for the database that contains these globals.
	// After that, enable journaling for the database.
	d ..newmap( "ds_facts", 1, "DeepSee.Fact,DeepSee.FactRelation,DeepSee.Index" )

	// Globals used to keep cube synchronized with the source table	
	// See the chapter “Keeping the Cubes Current.”
	d ..newmap( "ds_sync", 1, "OBJ.DSTIME,DeepSee.Update" ) 

	// Cube internals	
	d ..newmap( "ds_cubes", 1, "DeepSee.Cubes,DeepSee.Dimension,DeepSee.DimensionI" )
	 
	// Cube Manager - See “Using the Cube Manager” in “Keeping the Cubes Current.”
	d ..newmap( "ds_cubeman", 1, "DeepSee.CubeManager,DeepSee.CubeManager.CubeEventD,DeepSee.CubeManager.CubeEventI,DeepSee.CubeManager.CubeRegistr" )

	// Listing groups - See “Defining Listing Groups” in Defining DeepSee Models.
	d ..newmap( "ds_lists", 1, "DeepSee.ListingGroups" )

	// Result cache (for large data sets)	
	// You can disable journaling for the database that contains these globals.
	// For information on the result cache, see “Cube Updates and the Result Cache,” later in this book.
	d ..newmap( "ds_cache", 0, "DeepSee.BucketList,DeepSee.Cache.*,DeepSee.JoinIndex,DeepSee.UpdateCounter,DeepSee.Listing" )

	// Items created in the Analyzer and in the Dashboard Designer	
	// See Using the DeepSee Analyzer and Creating DeepSee Dashboards.
	d ..newmap( "ds_dash", 1, "DeepSee.Filters,DeepSee.Folder*,DeepSee.FolderItem*" )

	// Term lists - See the Advanced DeepSee Modeling Guide. 
	d ..newmap( "ds_terms", 1, "DeepSee.TermList" )

	// Quality measures - See the Advanced DeepSee Modeling Guide.
	d ..newmap( "ds_qual", 1, "DeepSee.QMsrs" )

	// Pivot variables - See “Defining and Using Pivot Variables” in Using the DeepSee Analyzer. 
	d ..newmap( "ds_vars", 1, "DeepSee.Variables" )

	// Other portal options	- See “Defining and Using Pivot Variables” in Using the DeepSee Analyzer.
	d ..newmap( "ds_opts", 1, 
	"DeepSee.DashboardSettings" _ // user-specific dashboard settings
	",DeepSee.User.SendTo" _  // user email addresses
	",DeepSee.User.Settings" _ // runtime variables
	",DeepSee.User.Icons" _ // custom icons
	",DeepSee.UserPortalSettings" _ // general settings and worklist settings
	",DeepSee.UserPreferences" _ // recent items, per user
	",DeepSee.PaperSizes" // see “Adding Paper Sizes,” later in this book
	)
	
	// Custom code - See the chapter “Other Development Work. 
	d ..newmap( "ds_cust", 1, "DeepSee.InitCode,DeepSee.AuditCode" )

	// Recent history and logs	
	d ..newmap( "ds_hist", 1, "DeepSee.AgentLog,DeepSee.Last*,DeepSee.PivotError,DeepSee.QueryLog,DeepSee.Session,DeepSee.SQLError" )
	 
	// iKnow	
	d ..newmap( "ds_iknow", 1, "ISC.IK.*" )
	 
	// Internals used for processing	
	d ..newmap( "ds_proces", 1, "DeepSee.ActiveTasks,DeepSee.Agents,DeepSee.Build,DeepSee.Cancel" _
	 ",DeepSee.ComputedSQL,DeepSee.Functions,DeepSee.IDList,DeepSee.Pivot,DeepSee.Shell" _
	 ",DeepSee.TaskGroups,DeepSee.Tasks,DeepSee.UI.Charts" )
}

ClassMethod newmap( suffix, journal, gls) As %Status {
	
	s dbname = $namespace _ "_" _ suffix
	s dbpath = $tr( suffix, "_", "/" )
	s dbpath = $zu( 12, dbpath )
	d ##class(%File).CreateDirectoryChain( dbpath )
	d ..createDb( dbname, dbpath, journal )
	s list = $lfs(gls), p=0, gl=""
	while $listnext(list, p, gl ){
		d ..moveGlobal( gl, dbpath )
		d ..mapGlobal( gl, dbname )
	}
	Q 1
}

/// Create non-journaling db for logs
ClassMethod createDb( name, path, journal) As %Status {
	n $namespace s $namespace = "%SYS"
	
	#; create file for db
	s db=##Class(SYS.Database).%New()
	s db.Directory = path 
	s db.GlobalJournalState = 3 // Journaling enabled
	s:'journal db.GlobalJournalState = 2 // 2 => Journaling disabled
	s sc = db.%Save() 
	Q:'sc sc 
	
	#; register dbfile in instance
	s conf("Directory")= path
	s sc = ##class(Config.Databases).Create( name, .conf )
	Q sc
}

/// Copy global to target database
/// And remove in current
ClassMethod moveGlobal( glname, dbpath) As %Boolean {
	s target = "^[""^^"_dbpath_"""]"_glname
	s source = "^"_glname
	try {
		m @target = @source
		k @source
	} catch e {
		
	}
	Q 1
}

/// Map global <var>glname</var> from <var>dbname</var> into <var>ns</var>
ClassMethod mapGlobal( glname, dbname, ns = {$namespace}) {
	n $namespace s $namespace = "%SYS"
	s props("Database") = dbname
	Q ##class(Config.MapGlobals).Create( ns, glname, .props )
}

}
