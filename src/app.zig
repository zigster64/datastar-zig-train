// just a struct for the world / app state
// just tracking a call count for now - but you can add anything in here to map the global app state
// The global instance of this is passed as the Context param to all http handlers

call_count: usize = 0,
