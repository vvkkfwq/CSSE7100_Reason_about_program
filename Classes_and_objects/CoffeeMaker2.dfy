class Grinder { 
	ghost var hasBeans: bool 
	ghost var Repr: set<object>

	ghost predicate Valid() 
		reads this, Repr
        ensures Valid() ==> this in Repr
		
	constructor() 
		ensures Valid() && fresh(Repr) && !hasBeans

	function Ready(): bool 
		requires Valid() 
		reads Repr
		ensures Ready() == hasBeans

	method AddBeans() 
		requires Valid() 
		modifies Repr 
		ensures Valid() && hasBeans && fresh(Repr-old(Repr))

	method Grind() 
		requires Valid() && hasBeans 
		modifies Repr 
		ensures Valid() && fresh(Repr-old(Repr))
}

class WaterTank { 
	ghost var waterLevel: nat
	ghost var Repr: set<object>

	ghost predicate Valid() 			 
		reads this, Repr 		
        ensures Valid() ==> this in Repr

	constructor() 				 
		ensures Valid() && fresh(Repr) && waterLevel == 0

	function Level(): nat 
		requires Valid()
		reads Repr
		ensures Level() == waterLevel

	method Fill() 
		requires Valid() 
		modifies Repr 
		ensures Valid() && fresh(Repr-old(Repr)) && waterLevel == 10 

	method Use() 
		requires Valid() && waterLevel != 0 
		modifies Repr 
		ensures Valid() && fresh(Repr-old(Repr)) && waterLevel == old(waterLevel) - 1  
}

class CoffeeMaker { 
	ghost var ready: bool
	ghost var Repr: set<object>
	var g: Grinder 	
	var w: WaterTank

	ghost predicate Valid() 
		reads this, Repr
		ensures Valid() ==> this in Repr
	{ 
		this in Repr && g in Repr && w in Repr &&
		g.Repr <= Repr && w.Repr <= Repr &&
		w.Repr !! g.Repr !! {this} &&
		g.Valid() && w.Valid() && 
		ready == (g.hasBeans && w.waterLevel != 0) 
	}

	constructor() 
		ensures Valid() && fresh(Repr)
	{ 
		g := new Grinder(); 
		w := new WaterTank(); 
		ready := false;
		new;
		Repr := {this, g, w} + g.Repr + w.Repr;
	}

	predicate Ready() 
		requires Valid() 
		reads Repr
		ensures Ready() == ready
	{ 
		g.Ready() && w.Level() != 0
	}

	method Restock() 
		requires Valid() 
		modifies Repr 
		ensures Valid() && Ready() && fresh(Repr - old(Repr))
	{ 
		assert w.Valid();
		assert w.Repr !! g.Repr;
		assert this !in g.Repr;
		g.AddBeans(); 
		assert w.Valid();
		w.Fill();  
		ready := true;
		Repr := Repr + g.Repr + w.Repr;
	} 

	method Dispense()
		requires Valid() && Ready() && w.waterLevel != 0 
		modifies Repr 
		ensures Valid() && fresh(Repr - old(Repr))
	{ 	
		g.Grind(); 
		w.Use(); 
		ready := g.hasBeans && w.waterLevel != 0;
		Repr := Repr + g.Repr + w.Repr;
	}
	
}

method TestHarness() { 
	var cm := new CoffeeMaker(); 
	cm.Restock();
	assert cm.Ready(); 
	cm.Dispense();
}

