package org.tuio.gestures {
	
	import flash.utils.getTimer;
	import flash.display.DisplayObject;
	import org.tuio.TuioContainer;
	
	/**
	 * This class is the heart of the <code>GestureManager</code>'s gesture system and handles the state of the multiple instances of a gesture.
	 * <p>The <code>GestureStepSequence</code> stores a sequence of <code>GestureStep</code>s that determine the events needed
	 * until a certain <code>GestureEvent</code> may be dispatched.</p>
	 * 
	 * <p>This class also provides the means to share targets, <code>TuioContainer</code>s, Tuio frameIDs and custom values between
	 * the steps and with the final dispatching of the <code>GestureEvent</code>.</p>
	 * 
	 */
	public class GestureStepSequence {
		
		private var steps:Array;
		private var stepPosition:uint;
		private var targetAliasMap:Object;
		private var tuioContainerAliasMap:Object;
		private var frameIDAliasMap:Object;
		private var values:Object;
		private var _gesture:Gesture;
		private var _active:Boolean;
		
		private static var recycleBin:Vector.<GestureStepSequence> = new Vector.<GestureStepSequence>();
		
		public function GestureStepSequence() {
			init();
		}
		
		/**
		 * Helper function for the constructor and getInstance.
		 */
		private function init():void {
			this.steps = [];
			this.targetAliasMap = {};
			this.tuioContainerAliasMap = {};
			this.frameIDAliasMap = {};
			this.values = {};
			this.stepPosition = 0;
			this._active = true;
		}
		
		/**
		 * @return An instance of <code>GestureStepSequence</code> leveraging object recycling.
		 */
		public function getInstance():GestureStepSequence {
			if (recycleBin.length > 0) {
				return recycleBin.pop().recycle();
			}else {
				return new GestureStepSequence();
			}
		}
		
		/**
		 * Recycles the GestureStepSequence object by deleting the original content.
		 */
		private function recycle():GestureStepSequence {
			init();
			return this;
		}
		
		/**
		 * Flags the <code>GestureStepSequence</code> and all contained <code>Gesture Steps</code> for future recycling
		 */
		internal function discard():void {
			recycleBin.push(this);
			var al:int = steps.length;
			for (var c:int = 0; c < al; c++ ) {
				(steps[c] as GestureStep).discard();
			}
		}
		
		/**
		 * @return A copy of the first <code>GestureStep</code> in the sequence.
		 */
		public function get firstStep():GestureStep {
			var step:GestureStep;
			for (var i:int = 0; i < steps.length; i++ ) {
				step = this.steps[i] as GestureStep;
				if(!step.dies) return step.copy();
			}
			return null;
		}
		
		/**
		 * The <code>Gesture</code> the <code>GestureStepSequence</code> belongs to.
		 */
		public function get gesture():Gesture {
			return this._gesture;
		}
		
		public function set gesture(g:Gesture):void {
			this._gesture = g;
		}
		
		/**
		 * Add a step at the end of the sequence
		 * 
		 * @param	s The step to be added.
		 */
		internal function addStep(s:GestureStep):void {
			s.group = this;
			this.steps.push(s);
		}
		
		/**
		 * Returns the target that was stored under the given alias. If no target was stored yet under the given alias <code>null</code> is returned.
		 * 
		 * @param	alias The alias name of the target.
		 * @return The target stored under the given alias.
		 */
		internal function getTarget(alias:String):DisplayObject {
			if (alias.charAt(0) == "!") return null;
			return this.targetAliasMap[alias] as DisplayObject;
		}
		
		/**
		 * Store a target under a given alias name. If the alias is already in use the old target will be overwritten.
		 * 
		 * @param	alias The alias name.
		 * @param	target The target to be saved.
		 */
		internal function addTarget(alias:String, target:DisplayObject):void {
			if (alias.charAt(0) == "!") alias = alias.substr(1);
			this.targetAliasMap[alias] = target;
		}
		
		/**
		 * Returns the <code>TuioContainer</code> that was stored under the given alias. If no <code>TuioContainer</code> was stored yet under the given alias <code>null</code> is returned.
		 * 
		 * @param	alias The alias name of the <code>TuioContainer</code>.
		 * @return The <code>TuioContainer</code> stored under the given alias.
		 */
		internal function getTuioContainer(alias:String):TuioContainer {
			if (alias.charAt(0) == "!") return null;
			return this.tuioContainerAliasMap[alias] as TuioContainer;
		}
		
		/**
		 * Store a <code>TuioContainer</code> under a given alias name. If the alias is already in use the old <code>TuioContainer</code> will be overwritten.
		 * 
		 * @param	alias The alias name.
		 * @param	target The <code>TuioContainer</code> to be saved.
		 */
		internal function addTuioContainer(alias:String, tuioContainer:TuioContainer):void {
			if (alias.charAt(0) == "!") alias = alias.substr(1);
			this.tuioContainerAliasMap[alias] = tuioContainer;
		}
		
		/**
		 * Returns the frameID that was stored under the given alias. If no framID was stored yet under the given alias 0 is returned.
		 * 
		 * @param	alias The alias name of the frameID.
		 * @return The frameID stored under the given alias.
		 */
		internal function getFrameID(alias:String):uint {
			if (alias.charAt(0) == "!") return 0;
			else return uint(this.frameIDAliasMap[alias]);
		}
		
		/**
		 * Store a frameID under a given alias name. If the alias is already in use the old frameID will be overwritten.
		 * 
		 * @param	alias The alias name.
		 * @param	target The frameID to be saved.
		 */
		internal function addFrameID(alias:String, frameID:uint):void {
			if (alias.charAt(0) == "!") alias = alias.substr(1);
			this.frameIDAliasMap[alias] = frameID;
		}
		
		/**
		 * Returns the alias of a given target. If the target wasn't stored yet with <code>addTarget(...)</code>, <code>null</code> is returned.
		 * 
		 * @param	target The target you want the alias of. 
		 * @return The given target's alias.
		 */
		internal function getTargetAlias(target:DisplayObject):String {
			return getKey(targetAliasMap, target);
		}
		
		/**
		 * Returns the alias of a given <code>TuioContainer</code>. If the <code>TuioContainer</code> wasn't stored yet with <code>addTuioContainer(...)</code>, <code>null</code> is returned.
		 * 
		 * @param	target The <code>TuioContainer</code> you want the alias of. 
		 * @return The given target's alias.
		 */
		internal function getTuioContainerAlias(tuioContainer:TuioContainer):String {
			return getKey(tuioContainerAliasMap, tuioContainer);
		}
		
		/**
		 * Returns the alias of a given frameID. If the frameID wasn't stored yet with <code>addFrameID(...)</code>, <code>null</code> is returned.
		 * 
		 * @param	target The frameID you want the alias of. 
		 * @return The given target's alias.
		 */
		internal function getFrameIDAlias(frameID:int):String {
			return getKey(frameIDAliasMap, frameID);
		}
		
		/**
		 * This function allows you to store a custom value. This may be used to share certain values between iterations of the same <code>GestureStepSequence</code>.
		 * If the key is already in use the old value will be overwritten.
		 * 
		 * @param	key The key under which the value will be stored.
		 * @param	value The value to be stored.
		 */
		internal function storeValue(key:String, value:Object):void {
			this.values[key] = value;
		}
		
		/**
		 * This function returns a custom value tha was previously stored under the given key.
		 * If no value was stored under the given key <code>null</code> is returned.
		 * 
		 * @param	key The key of the value to be retrieved.
		 * @return The stored value.
		 */
		internal function getValue(key:String):Object {
			return this.values[key];
		}
		
		/**
		 * Returns the key of a given value in a given associative array.
		 * 
		 * @param	a The associative array.
		 * @param	value The value of which you want the key.
		 * @return The key the value is stored under.
		 */
		private function getKey(a:Object, value:Object):String {
			for(var k:String in a) {
				if (a[k] == value) return k;
			} 
			return null;
		}
		
		/**
		 * Progresses the <code>GestureStepSequence</code> for one or multiple steps until a non optional one.
		 * Optional <code>GestureStep</code>s are currently only the ones that have <code>die</code> set <code>true</code>.
		 * 
		 * @param	event The events name that shall be checked against.
		 * @param	target The target <code>DisplayObject</code> of the event.
		 * @param	tuioContainer The <code>TuioContainer</code> that triggered the event.
		 * @return A value stating whether the <code>GestureStepSequence</code> progressed, is alive, is fully saturated or died. Those values are constants of <code>Gesture</code>
		 */
		public function step(event:String, target:DisplayObject, tuioContainer:TuioContainer):uint {

			var step:GestureStep = this.steps[stepPosition] as GestureStep;
			var result:uint = step.step(event, target, tuioContainer);
			var dieOffset:int = 0;
			var gotoStep:int;

			while (true) {
				if (result == Gesture.SATURATED && !step.dies) {
					stepPosition++;
					this.gesture.dispatchEvent(new GestureStepEvent(GestureStepEvent.SATURATED, stepPosition, this));
					if (stepPosition < steps.length) {
						gotoStep = step.gotoStep;
						if (gotoStep > 0 && gotoStep <= steps.length) stepPosition = gotoStep - 1;
						prepareNext();
						return Gesture.PROGRESS;
					} else {
						gotoStep = step.gotoStep;
						if (gotoStep > 0 && gotoStep <= steps.length) {
							stepPosition = gotoStep - 1;
							prepareNext();
						} else {
							this._active = false;
						}
						return Gesture.SATURATED;
					}
				} else if (result == Gesture.ALIVE || (result == Gesture.DEAD && (step.dies || step.optional))) {
					if (step.dies || step.optional) {
						stepPosition++;
						dieOffset++;
						step = this.steps[stepPosition] as GestureStep;
						result = step.step(event, target, tuioContainer);
					} else {
						stepPosition -= dieOffset;
						return Gesture.ALIVE;
					}
				} else {
					this.gesture.dispatchEvent(new GestureStepEvent(GestureStepEvent.DEAD, stepPosition+1, this));
					this._active = false;
					return Gesture.DEAD;
				}
			}
			
			return Gesture.ALIVE;
		}
		
		/**
		 * Prepares the next step.
		 * Starts the timeout counter.
		 */
		private function prepareNext():void {
			var o:int = 0;
			var nextStep:GestureStep = this.steps[stepPosition];
			var stepLength:int = this.steps.length-1;
			nextStep.prepare();
			while(nextStep.dies && (stepPosition + o) < stepLength ) {
				o++;
				nextStep = this.steps[stepPosition + o];
				nextStep.prepare();
			}
		}
		
		/**
		 * @return A copy of the basic <code>GestureStepSequence</code> but not its current state and stored values.
		 */
		public function copy():GestureStepSequence {
			var out:GestureStepSequence = getInstance();
			out.gesture = this.gesture;
			var al:int = steps.length;
			for (var c:int = 0; c < al; c++ ) {
				out.addStep((steps[c] as GestureStep).copy());
			}
			return out;
		}
	
		/**
		 * <code>true</code> if still alive/active, otherwise <code>false</code>.
		 */
		public function get active():Boolean {
			return this._active;
		}
		
	}
	
}