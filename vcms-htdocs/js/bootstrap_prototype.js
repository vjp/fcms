/* ===========================================================
 * bootstrap_prototype.js v2.3.2
 * http://twitter.github.com/bootstrap/javascript.html
 * ===========================================================
 * Copyright 2012 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================== */
/*

Modified for use with PrototypeJS

http://github.com/jwestbrook/bootstrap-prototype


*/
/* BUILD TIME Sat May 03 2014 08:07:36 GMT-0700 (PDT) */

"use strict";
var BootStrap = {
	transitionendevent : null,
	handleeffects : null
	};

//Test CSS transitions first - less JS to implement
var transEndEventNames = $H({
	'WebkitTransition' : 'webkitTransitionEnd',
	'MozTransition'    : 'transitionend',
	'OTransition'      : 'oTransitionEnd otransitionend',
	'transition'       : 'transitionend'
});

var el = new Element("bootstrap");
transEndEventNames.each(function(pair){
	if(el.style[pair.key] !== undefined)
	{
		BootStrap.transitionendevent = pair.value;
		BootStrap.handleeffects = 'css';
	}
});

//then go to scriptaculous

if(BootStrap.handleeffects === null && typeof Effect !== 'undefined')
{
	BootStrap.handleeffects = 'effect';
}

//BootStrap.Affix
BootStrap.Affix = Class.create({
	initialize : function (element, options) {
		this.$element = $(element)
		this.$element.store('bootstrap:affix',this)
		//defaults
		this.options = {
			offset: 0
		}

		Object.extend(this.options, options)

		Event.observe(window,'scroll',this.checkPosition.bind(this))
		Event.observe(window,'click',function(){
			setTimeout(this.checkPosition.bind(this),1)
		}.bind(this))
		this.checkPosition()
	},
	checkPosition : function () {
		if (!this.$element.visible()) return

		var scrollHeight = document.height
		, scrollTop = window.pageYOffset || document.documentElement.scrollTop
		, position = this.$element.positionedOffset()
		, offset = this.options.offset
		, offsetBottom = offset.bottom
		, offsetTop = offset.top
		, reset = 'affix affix-top affix-bottom'
		, affix

		if (typeof offset != 'object') offsetBottom = offsetTop = offset
		if (typeof offsetTop == 'function') offsetTop = offset.top()
		if (typeof offsetBottom == 'function') offsetBottom = offset.bottom()

		affix = this.unpin != null && (scrollTop + this.unpin <= position.top) ?
			false    : offsetBottom != null && (position.top + this.$element.getHeight() >= scrollHeight - offsetBottom) ?
				'bottom' : offsetTop != null && scrollTop <= offsetTop ?
					'top'    : false

		if (this.affixed === affix) return

		this.affixed = affix
		this.unpin = affix == 'bottom' ? position.top - scrollTop : null

		this.$element.removeClassName(reset).addClassName('affix' + (affix ? '-' + affix : ''))
	}
});

Event.observe(window,'load',function(){
	$$('[data-spy="affix"]').each(function($spy){
		var data = {}
		data.offset = $spy.hasAttribute('data-offset') ? $spy.readAttribute('data-offset') : {}
		$spy.hasAttribute('data-offset-bottom') ? data.offset.bottom = $spy.readAttribute('data-offset-bottom') : ''
		$spy.hasAttribute('data-offset-top') ? data.offset.top = $spy.readAttribute('data-offset-top') : ''

		new BootStrap.Affix($spy,data);
	})
})

//BootStrap.Alert
BootStrap.Alert = Class.create({
	initialize : function (element) {
		element.store('bootstrap:alert',this)
		$(element).observe('click',this.close)
	},
	close : function (e) {
		var $this = $(this)
		var selector = $this.readAttribute('data-target')
		var $parent

	
		if (!selector) {
			selector = $this.href
			selector = selector && selector.replace(/.*(?=#[^\s]*$)/, '').replace('#','') //strip for ie7
		}
		
		(selector !== undefined && selector.length > 0) ? $parent = $(selector) : '';
	
		($parent !== undefined && $parent.length) || ($parent = $this.hasClassName('alert') ? $this : $this.up())
	
		var closeEvent = $parent.fire('bootstrap:close')

		if(closeEvent.defaultPrevented) return
	
		function removeElement() {
			$parent.fire('bootstrap:closed')
			$parent.remove()
		}
	
		if(BootStrap.handleeffects === 'css' && $parent.hasClassName('fade'))
		{
			$parent.observe(BootStrap.transitionendevent,function(){
				removeElement();
			});
			$parent.removeClassName('in')
		}
		else if(BootStrap.handleeffects === 'effect' && $parent.hasClassName('fade'))
		{
			new Effect.Fade($parent,{duration:0.3,from:$parent.getOpacity()*1,afterFinish:function(){
				$parent.removeClassName('in')
				removeElement()
			}})
		}
		else
		{
			removeElement()
		}

	}
});

//BootStrap.Button
BootStrap.Button = Class.create({
	initialize : function (element, options) {
		element.store('bootstrap:button',this)
		this.$element = $(element)
		if(typeof options == 'object')
		{
			this.options = options
			this.options.loadingText = (typeof this.options.loadingText != 'undefined') ? options.loadingText : ''
		} else if(typeof options != 'undefined' && options == 'toggle') {
			this.toggle()
		} else if (typeof options != 'undefined'){
			this.setState(options)
		}

	},
	setState : function (state) {
		var d = 'disabled'
		, $el = this.$element
		, val = $el.readAttribute('type') == 'input' ? 'value' : 'innerHTML'

		state = state + 'Text'
		$el.readAttribute('data-reset-text') || $el.writeAttribute('data-reset-text',$el[val])

		$el[val] = ($el.readAttribute('data-'+state.underscore().dasherize()) || (this.options && this.options[state]) || '')

		// push to event loop to allow forms to submit
		setTimeout(function () {
			state == 'loadingText' ?
			$el.addClassName(d).writeAttribute(d,true) :
			$el.removeClassName(d).writeAttribute(d,false)
		}, 0)
	},
	toggle : function () {
		var $parent = this.$element.up('[data-toggle="buttons-radio"]')

		$parent && $parent
		.select('.active')
		.invoke('removeClassName','active')

		this.$element.toggleClassName('active')
	}
});


//BootStrap.Carousel
BootStrap.Carousel = Class.create({

	initialize : function (element, options) {
		this.options = {
			interval: 5000
			, pause: 'hover'
			}
		this.$element = $(element)
		this.options.interval = this.$element.hasAttribute('data-interval') ? this.$element.readAttribute('data-interval') : this.options.interval
		element.store('bootstrap:carousel',this)
		this.$indicators = this.$element.down('.carousel-indicators')
		Object.extend(this.options,options)

		this.options.slide && this.slide(this.options.slide)
		this.options.pause == 'hover' && this.$element.on('mouseenter', this.pause.bind(this)) && this.$element.on('mouseleave', this.cycle.bind(this))
		
		if(this.options.interval)
		{
			this.cycle()
		}
		
	}
	, cycle: function (e) {
		if (!e) this.paused = false
		this.options.interval
			&& !this.paused
			&& (this.interval = setInterval(this.next.bind(this), this.options.interval))
		return this
	}
	, getActiveIndex: function () {
		this.$active = this.$element.down('.item.active')
		this.$items = this.$active.up().childElements()
		return this.$items.indexOf(this.$active)
	}
	, to: function (pos) {
		var $active = this.$element.down('.item.active')
		, children = $active.up().childElements()
		, activePos = children.indexOf($active)
		
		if (pos > (children.length - 1) || pos < 0) return
		
		if (this.sliding) {
			return this.$element.on('bootstrap:slid', function () {
				this.to(pos)
				}.bind(this))
		}
		
		if (activePos == pos) {
			return this.pause().cycle()
		}
		
		return this.slide(pos > activePos ? 'next' : 'previous', $(children[pos]))
	}
	, pause: function (e) {
		if (!e) this.paused = true
		if (this.$element.select('.next, .prev').length && BootStrap.handleeffects == 'css') {
			this.$element.fire(BootStrap.transitionendevent)
			this.cycle()
		}
		clearInterval(this.interval)
		this.interval = null
		return this
	}
	, next: function () {
		if (this.sliding) return
		return this.slide('next')
	}
	, prev: function () {
		if (this.sliding) return
		return this.slide('previous')
	}
	, slide: function (type, next) {
		var $active = this.$element.down('.item.active')
		, $next = next || $active[type]()
		, isCycling = this.interval
		, direction = type == 'next' ? 'left' : 'right'
		, fallback  = type == 'next' ? 'first' : 'last'
		, that = this
		, e
		, slideEvent
		
		this.sliding = true
		
		isCycling && this.pause()

		$next = $next !== undefined ? $next : this.$element.select('.item')[fallback]()

		type = (type == 'previous' ? 'prev' : type)
/*
		e = $.Event('slide', {
			relatedTarget: $next[0]
		})
*/
		
		if ($next.hasClassName('active')) return
		
		if (this.$indicators) {
			this.$indicators.down('.active').removeClassName('active')
			this.$element.on('bootstrap:slid', function () {
				var $nextIndicator = $(this.$indicators.childElements()[this.getActiveIndex()])
				$nextIndicator && $nextIndicator.addClassName('active')
				this.$element.stopObserving('bootstrap:slid')
			}.bind(this))
		}



		if (BootStrap.handleeffects == 'css' && this.$element.hasClassName('slide')) {
			slideEvent = this.$element.fire('bootstrap:slide')
			if(slideEvent.defaultPrevented) return

			this.$element.on(BootStrap.transitionendevent, function (e) {
				$next.removeClassName([type, direction].join(' ')).addClassName('active')
				$active.removeClassName(['active', direction].join(' '))
				this.sliding = false
				setTimeout(function () { this.$element.fire('bootstrap:slid') }.bind(this), 0)
				isCycling && this.cycle()
				this.$element.stopObserving(BootStrap.transitionendevent)
			}.bind(this))


			$next.addClassName(type)
			$next.offsetWidth // force reflow
			$active.addClassName(direction)
			$next.addClassName(direction)
		} else if(BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.Morph !== 'undefined'){
			
			new Effect.Parallel([
				new Effect.Morph($next,{'sync':true,'style':'left:0%;'}),
				new Effect.Morph($active,{'sync':true,'style':'left:'+( direction == 'left' ? '-' : '' )+'100%;'})
			],{
				'duration':0.6,
				'beforeSetup':function(effect){
					$next.addClassName(type)
					this.sliding = true
				}.bind(this),
				'afterFinish':function(effect){
					$next.removeClassName(type).addClassName('active')
					$active.removeClassName('active')
					$next.style[direction] = null;
					$active.style[direction] = null;
					this.sliding = false
					this.$element.fire('bootstrap:slid')
					isCycling && this.cycle()
				}.bind(this)
			})
			
		} else {
			slideEvent = this.$element.fire('bootstrap:slide')
			if(slideEvent.defaultPrevented) return
			$active.removeClassName('active')
			$next.addClassName('active')
			this.sliding = false
			this.$element.fire('bootstrap:slid')
			isCycling && this.cycle()
		}
		
		return this
	}
});

//BootStrap.Collapse
BootStrap.Collapse = Class.create({
	initialize : function (element, options) {
		this.$element = $(element)
		
		element.store('bootstrap:collapse',this)
		
		this.options = {
			toggle: true
		}
		
		Object.extend(this.options,options)
		
		
		if (this.options.parent) {
			this.$parent = $(this.options.parent)
		}
		
		var dimension = this.dimension()
		if(this.$element.style[dimension] === 'auto')
		{
			var scroll = ['scroll', dimension].join('-').camelize()
			this.reset(this.$element[scroll]+'px')
		}
		
		this.options.toggle && this.toggle()
	}
	
	, dimension: function () {
		var hasWidth = this.$element.hasClassName('width')
		return hasWidth ? 'width' : 'height'
	}
	
	, show: function () {
		var dimension
		, scroll
		, actives
		, hasData
		
		if (this.transitioning) return
		
		dimension = this.dimension()
		scroll = ['scroll', dimension].join('-').camelize()
		actives = this.$parent && this.$parent.select('> .accordion-group > .in')
		
		if (actives && actives.length) {
			actives.each(function(el){
				var bootstrapobject = el.retrieve('bootstrap:collapse')
				if (bootstrapobject && bootstrapobject.transitioning) return
				bootstrapobject.hide()
			});
		}
		
		var newstyle = {}
		newstyle[dimension] = '0px'
		this.$element.setStyle(newstyle)
		this.transition('addClassName', 'show', 'bootstrap:shown')
		
		if(BootStrap.handleeffects == 'css'){
			newstyle = {}
			newstyle[dimension] = this.$element[scroll]+'px'
//			newstyle[dimension] = 'auto'
			this.$element.setStyle(newstyle)
		} else if(BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.BlindDown !== 'undefined'){
			this.$element.blindDown({duration:0.5,afterFinish:function(effect){
//				effect.element[method]('in')
				newstyle = {}
				newstyle[dimension] = this.$element[scroll]+'px'
				this.$element.setStyle(newstyle)
			}.bind(this)})
		/*	this.$element[dimension](this.$element[scroll] */
		}
	}
	
	, hide: function () {
		var dimension
		if (this.transitioning) return
		dimension = this.dimension()
		this.reset(this.$element.getStyle(dimension))
		this.transition('removeClassName', 'hide', 'bootstrap:hidden')
		this.reset('0px')
		if(BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && Effect.Queues.get('global').effects.length === 0)
		{
			var newstyle = {}
			newstyle[dimension] = '0px'
			this.$element.setStyle(newstyle)
		}
	}
	
	, reset: function (size) {
		var dimension = this.dimension()
		
		this.$element
			.removeClassName('collapse')
		
		var newstyle = {}
		newstyle[dimension] = size
		this.$element.setStyle(newstyle)
		
		this.$element[size !== null ? 'addClassName' : 'removeClassName']('collapse')
		
		return this
	}
	
	, transition: function (method, startEvent, completeEvent) {
		var that = this
		, complete = function () {
			if (startEvent == 'show') this.reset()
			this.transitioning = 0
			this.$element.fire(completeEvent)
		}.bind(this)
		
		var startEventObject = this.$element.fire('bootstrap:'+startEvent)

		if(startEventObject.defaultPrevented) return
		
		this.transitioning = 1
		
		if(BootStrap.handleeffects == 'css' && this.$element.hasClassName('collapse')){
			this.$element.observe(BootStrap.transitionendevent, complete)
			this.$element[method]('in')
		} else if(startEvent == 'hide' && BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.BlindUp !== 'undefined') {
			this.$element.blindUp({duration:0.5,afterFinish:function(effect){
				var dimension = this.dimension()
				effect.element[method]('in')
				var newstyle = {}
				newstyle[dimension] = '0px'
				this.$element.setStyle(newstyle)
				complete()
			}.bind(this)})
		} else if(startEvent == 'show' && BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.BlindUp !== 'undefined') {
			this.$element.blindDown({duration:0.5,beforeStart:function(effect){
				var dimension = this.dimension()
				effect.element[method]('in')
				var newstyle = {}
				newstyle[dimension] = 'auto'
				this.$element.setStyle(newstyle)
				effect.element.hide()
			}.bind(this),afterFinish:function(effect){
				complete()
			}.bind(this)})
		}
		else {
			complete()
			this.$element[method]('in')
		}
		
		
		
	}
	
	, toggle: function () {
		this[this.$element.hasClassName('in') ? 'hide' : 'show']()
	}
	
});




//BootStrap.Dropdown
BootStrap.Dropdown = Class.create({
	initialize : function (element) {
		element.store('bootstrap:dropdown',this)
		var $el = $(element).on('click',this.toggle)
		$$('html')[0].on('click', function () {
			$el.up().removeClassName('open')
		})
	}
	,toggle: function (e) {
		var $this = $(this)
		, $parent
		, isActive

		if ($this.hasClassName('disabled') || $this.readAttribute('disabled') == 'disabled') return

		$parent = BootStrap.Dropdown.prototype.getParent($this)

		isActive = $parent.hasClassName('open')

		BootStrap.Dropdown.prototype.clearMenus()

		if (!isActive) {
			if ('ontouchstart' in document.documentElement) {
				// if mobile we we use a backdrop because click events don't delegate
				var backdrop = new Element('div',{'class':'dropdown-backdrop'});
				backdrop.observe('click',BootStrap.Dropdown.prototype.clearMenus);
				$this.insert({'before':backdrop})
			}

			$parent.toggleClassName('open')
		}

		$this.focus()

		e.stop()
	}
	, keydown: function (e) {
		var $this
		, $items
		, $active
		, $parent
		, isActive
		, index

		if (!/(38|40|27)/.test(e.keyCode)) return

		$this = $(this)

		e.preventDefault()
		e.stopPropagation()

		if ($this.hasClassName('disabled') || $this.readAttribute('disabled') == 'disabled') return

		$parent = BootStrap.Dropdown.prototype.getParent($this)

		isActive = $parent.hasClassName('open')

		if (!isActive || (isActive && e.keyCode == Event.KEY_ESC))
		{
			if (e.which == Event.KEY_ESC) $parent.select('[data-toggle=dropdown]')[0].focus()
			return $this.click()
		}

		// :visible is a jQuery extension - NOT VALID CSS
		//      $items = $parent.select('[role=menu] li:not(.divider):visible a')
		//
		$items = $parent.select('[role=menu] li:not(.divider) a')

		if (!$items.length) return

		index = -1
		$items.each(function(item,i){
		item.match(':focus') ? index = i : ''
		})

		if (e.keyCode == Event.KEY_UP && index > 0) index--                                        // up
		if (e.keyCode == Event.KEY_DOWN && index < $items.length - 1) index++                        // down
		if (!~index) index = 0

		$items[index].focus()
	}
	, clearMenus : function(){
		$$('.dropdown-backdrop').invoke('remove')
		$$('[data-toggle=dropdown]').each(function(i) {
			BootStrap.Dropdown.prototype.getParent(i).removeClassName('open')
		})
	}
	, getParent : function(element){
		var selector = element.readAttribute('data-target')
		, $parent

		if (!selector) {
			selector = element.readAttribute('href')
			selector = selector && /#/.test(selector) && selector.replace(/.*(?=#[^\s]*$)/, '') && selector != '#' //strip for ie7
		}

		$parent = selector && $$(selector)

		if (!$parent || !$parent.length) $parent = element.up()

		return $parent

	}
});

//BootStrap.Modal
BootStrap.Modal = Class.create({
	initialize : function (element, options) {
		element.store('bootstrap:modal',this)
		this.$element = $(element);
		this.options = options !== undefined ? options : {}
		this.options.backdrop = this.options.backdrop !== undefined ? options.backdrop : true
		this.options.keyboard = this.options.keyboard !== undefined ? options.keyboard : true
		this.options.show = this.options.show !== undefined ? options.show : true


		if(this.options.show)
			this.show();
		$$("[data-dismiss='modal']").invoke("observe","click",function(){
			this.hide()
		}.bind(this))

		if(this.options.remote && this.$element.select('.modal-body')) {
			var t = new Ajax.Updater(this.$element.select('.modal-body')[0],this.options.remote);
		}
	},
	toggle: function () {
		return this[!this.isShown ? 'show' : 'hide']()
	}
	, show: function (e) {
		var that = this

		this.$element.setStyle({display:'block'})

		var showEvent = this.$element.fire('bootstrap:show')

		if (this.isShown || showEvent.defaultPrevented) return

		this.isShown = true

		this.escape()

		this.backdrop(function () {
			var transition = (BootStrap.handleeffects == 'css' || (BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.Fade !== 'undefined')) && that.$element.hasClassName('fade')

			if (that.$element.up('body') === undefined) {
				$$("body")[0].insert(that.$element);
			}
			that.$element.setStyle({display:'block'})

			if(transition && BootStrap.handleeffects == 'css') {
				that.$element.observe(BootStrap.transitionendevent,function(){
					that.$element.fire("bootstrap:shown");
				});
				setTimeout(function(){
					that.$element.addClassName('in').writeAttribute('aria-hidden',false);
				},1);
			} else if(transition && BootStrap.handleeffects == 'effect') {
				new Effect.Parallel([
					new Effect.Morph(that.$element,{sync:true,style:'top:10%'}),
					new Effect.Opacity(that.$element,{sync:true,from:0,to:1})
				],{duration:0.3,afterFinish:function(){
					that.$element.addClassName('in').writeAttribute('aria-hidden', false)
					that.$element.fire("bootstrap:shown");
				}})
			} else {
				that.$element.addClassName('in').writeAttribute('aria-hidden', false).fire("bootstrap:shown");
			}

			that.enforceFocus()
		})
	}
	, hide: function (e) {

		var that = this

		var hideEvent = this.$element.fire('bootstrap:hide')

		if (!this.isShown || hideEvent.defaultPrevented) return

		this.isShown = false

		this.escape()

		if(BootStrap.handleeffects == 'css' && this.$element.hasClassName('fade')) {
			this.hideWithTransition()
		} else if(BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.Fade !== 'undefined' && this.$element.hasClassName('fade')) {
			this.hideWithTransition()
		} else {
			this.hideModal()
			this.$element.setStyle({display:''});
		}
	}
	, enforceFocus: function () {
		var that = this
		$(document).on('focus', function (e) {
			if (that.$element[0] !== e.target && !that.$element.has(e.target).length) {
				that.$element.focus()
			}
		})
	}

	, escape: function () {
		var that = this
		if (this.isShown && this.options.keyboard) {
			$(document).on('keyup', function (e) {
				e.which == Event.KEY_ESC && that.hide()
			})
		} else if (!this.isShown) {
			$(document).stopObserving('keyup')
		}
	}

	, hideWithTransition: function () {
		var that = this

		if(BootStrap.handleeffects == 'css') {
			this.$element.observe(BootStrap.transitionendevent,function(){
				this.setStyle({display:''});
				this.setStyle({top:''})
				that.hideModal()
				this.stopObserving(BootStrap.transitionendevent)
			})
			setTimeout(function(){
				this.$element.removeClassName('in').writeAttribute('aria-hidden',true)
			}.bind(this))
		} else {
			new Effect.Morph(this.$element,{duration:0.30,style:'top:-25%;',afterFinish:function(effect){
				effect.element.removeClassName('in').writeAttribute('aria-hidden', true)
				effect.element.setStyle({display:''});
				effect.element.setStyle({top:''})
				that.hideModal()
			}})
		}
	}

	, hideModal: function () {
		this.$element.hide()
		this.backdrop(function(){
			this.removeBackdrop()
			this.$element.fire('bootstrap:hidden')
		}.bind(this))

	}
	, removeBackdrop: function () {
		this.$backdrop && this.$backdrop.remove()
		this.$backdrop = null
	}

	, backdrop: function (callback) {

		var that = this
		, animate = this.$element.hasClassName('fade') ? 'fade' : ''

		if (this.isShown && this.options.backdrop) {
			var doAnimate = (BootStrap.handleeffects == 'css' || (BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.Fade !== 'undefined')) && animate

			this.$backdrop = new Element("div",{"class":"modal-backdrop "+animate})
			if(doAnimate && BootStrap.handleeffects == 'css') {
				this.$backdrop.observe(BootStrap.transitionendevent,function(){
					callback()
					this.stopObserving(BootStrap.transitionendevent)
				})
			} else if(doAnimate && BootStrap.handleeffects == 'effect') {
				this.$backdrop.setOpacity(0)
			}

			this.$backdrop.observe("click",function(){
				that.options.backdrop == 'static' ? '' : that.hide()
			})

			$$("body")[0].insert(this.$backdrop)

			if(doAnimate && BootStrap.handleeffects == 'effect') {
				new Effect.Appear(this.$backdrop,{from:0,to:0.80,duration:0.3,afterFinish:callback})
			} else {
				callback();
			}
			setTimeout(function(){
				$$('modal-backdrop').invoke('addClassName','in')
			},1);


		} else if (!this.isShown && this.$backdrop) {
			if(animate && BootStrap.handleeffects == 'css'){
				that.$backdrop.observe(BootStrap.transitionendevent,function(){
					callback()
				});
				setTimeout(function(){
					that.$backdrop.removeClassName('in')
				},1);
			} else if(animate && BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.Fade !== 'undefined') {
				new Effect.Fade(that.$backdrop,{duration:0.3,from:that.$backdrop.getOpacity()*1,afterFinish:function(){
					that.$backdrop.removeClassName('in')
					callback()
				}})
			} else {
				that.$backdrop.removeClassName('in')
				callback()
			}

		} else if (callback) {
			callback()
		}
	}
});



//BootStrap.Tooltip
BootStrap.Tooltip = Class.create({
	initialize : function (element, options) {
		element.store('bootstrap:tooltip',this)
	
		this.options = {
			animation: true
			, placement: element.hasAttribute('data-placement') ? element.readAttribute('data-placement') : 'top'
			, selector: false
			, template: new Element('div',{'class':'tooltip'}).insert(new Element('div',{'class':'tooltip-arrow'})).insert(new Element('div',{'class':'tooltip-inner'}))
			, trigger: 'hover focus'
			, title: ''
			, delay: 0
			, html: false
			, container: false
		};
		Object.extend(this.options,options);

		if(typeof this.options.container == 'string'){
			this.options.container = $$(this.options.container).first()
		}

		if(typeof this.options.template == 'string'){
			this.options.template = new Element('div').update(this.options.template).down();
		}

		if (this.options.delay && typeof this.options.delay == 'number') {
			this.options.delay = {
				show: options.delay
				, hide: options.delay
			}
		}
		if(this.options.subclass === undefined) {
			this.init('tooltip', element)
		}
	}
	, init: function (type, element) {
		var eventIn
		, eventOut
		, triggers
		, trigger
		, i
		
		
		this.type = type
		this.$element = $(element)
		this.enabled = true
		
		triggers = this.options.trigger.split(' ')
		
		triggers.each(function(tr){
			if(tr == 'click' && this.options.selector) {
				this.$element.on('click',this.options.selector, this.toggle.bind(this))
			} else if(tr == 'click') {
				this.$element.observe('click', this.toggle.bind(this))
			} else if (tr != 'manual') {
				eventIn = tr == 'hover' ? 'mouseenter' : 'focus'
				eventOut = tr == 'hover' ? 'mouseleave' : 'blur'
				this.$element.observe(eventIn, this.enter.bind(this))
				this.$element.observe(eventOut, this.leave.bind(this))
			}
		},this)

		if(this.options.selector){
			this.$element = this.$element.down(this.options.selector)
			this.$element.store('bootstrap:tooltip',this)
			this.fixTitle()
		} else {
			this.fixTitle()
		}
	}
	, enter: function (e) {
		var defaults = this.defaults
			, options = {}
			, self
		
		this._options && $H(this._options).each(function(item){
			if(defaults[item.key] != item.value) options[item.key] = item.value
		}.bind(this))

		self = this

		if (!self.options.delay || !self.options.delay.show) return self.show()
		
		clearTimeout(this.timeout)
		self.hoverState = 'in'
		this.timeout = setTimeout(function() {
			if (self.hoverState == 'in') self.show()
		}, self.options.delay.show)
	}
	
	, leave: function (e) {
		var self = this
		
		if (this.timeout) clearTimeout(this.timeout)
		if (!self.options.delay || !self.options.delay.hide) return self.hide()
		
		self.hoverState = 'out'
		this.timeout = setTimeout(function() {
			if (self.hoverState == 'out') self.hide()
		}, self.options.delay.hide)
	}
	
	, show: function () {
		var $tip
		, pos
		, actualWidth
		, actualHeight
		, placement
		, tp
		, layout

		if (this.hasContent() && this.enabled) {
			var showEvent = this.$element.fire('bootstrap:show')
			if(showEvent.defaultPrevented) return
			$tip = this.tip()
			this.setContent()
			
			if (this.options.animation) {
				$tip.addClassName('fade')
			}
			
			placement = typeof this.options.placement == 'function' ?
			this.options.placement.call(this, $tip[0], this.$element[0]) :
			this.options.placement
			
			$tip.setStyle({ top: 0, left: 0, display: 'block' })

			this.options.container ? this.options.container.insert($tip) : this.$element.insert({'after':$tip})
			
			pos = this.getPosition()
			
			actualWidth = $tip.offsetWidth
			actualHeight = $tip.offsetHeight
			
			switch (placement) {
				case 'bottom':
					tp = {top: pos.top + pos.height, left: pos.left + pos.width / 2 - actualWidth / 2}
				break
				case 'top':
					tp = {top: pos.top - actualHeight, left: pos.left + pos.width / 2 - actualWidth / 2}
				break
				case 'left':
					tp = {top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left - actualWidth}
				break
				case 'right':
					tp = {top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left + pos.width}
				break
			}
			tp.top = tp.top+'px'
			tp.left = tp.left+'px'
			
			this.applyPlacement(tp,placement)
			this.$element.fire('bootstrap:shown')
			
		}
	}
	, applyPlacement: function(offset, placement){
		
		var $tip = this.tip()
			, width = $tip.offsetWidth
			, height = $tip.offsetHeight
			, actualWidth
			, actualHeight
			, delta
			, replace
		
		$tip
			.setStyle(offset)
			.addClassName(placement)
			.addClassName('in')
			
		offset.top = offset.top.replace('px','')*1
		offset.left = offset.left.replace('px','')*1
		
		actualWidth = $tip.offsetWidth
		actualHeight = $tip.offsetHeight
		
		if (placement == 'top' && actualHeight != height) {
			offset.top = offset.top + height - actualHeight
			replace = true
		}
		
		if (placement == 'bottom' || placement == 'top') {
			delta = 0
			
			if (offset.left < 0){
				delta = offset.left * -2
				offset.left = 0
				offset.top += 'px'
				offset.left += 'px'
				$tip.setStyle(offset)
				actualWidth = $tip.offsetWidth
				actualHeight = $tip.offsetHeight
			}
			
			this.replaceArrow(delta - width + actualWidth, actualWidth, 'left')
		} else {
			this.replaceArrow(actualHeight - height, actualHeight, 'top')
		}

		if(typeof offset.top === 'string' && !offset.top.match(/px/)){
			offset.top += 'px'
			offset.left += 'px'
		}
		if (replace) $tip.setStyle(offset)
	}
	, replaceArrow: function(delta, dimension, position){
		this.arrow().length ? this.arrow()[0].setStyle({
												position : (delta ? (50 * (1 - delta / dimension) + "%") : '')
												}) : ''
	}	
	, setContent: function () {
		var $tip = this.tip()
		, title = this.getTitle()
		if(!this.options.html){
			title = title.escapeHTML()
		}
		
		$tip.down('.tooltip-inner').update(title)
		$tip.removeClassName('fade in top bottom left right')
	}
	
	, hide: function () {
		var that = this
		, $tip = this.tip()

		var hideEvent = this.$element.fire('bootstrap:hide')
		if(hideEvent.defaultPrevented) return
		
		if(BootStrap.handleeffects == 'css' && this.$tip.hasClassName('fade')){
			var timeout = setTimeout(function () {
				$tip.stopObserving(BootStrap.transitionendevent)
				$tip ? $tip.remove() : ''
			}, 500)
			
			$tip.observe(BootStrap.transitionendevent, function () {
				clearTimeout(timeout)
				$tip ? $tip.remove() : ''
				this.stopObserving(BootStrap.transitionendevent)
				that.$element.fire('bootstrap:hidden')
			})
			$tip.removeClassName('in')
		} else if(BootStrap.handleeffects == 'effect' && this.$tip.hasClassName('fade')) {
			new Effect.Fade($tip,{duration:0.3,from:$tip.getOpacity()*1,afterFinish:function(){
				$tip.removeClassName('in')
				$tip.remove()
				that.$element.fire('bootstrap:hidden')
			}})
		} else {
			$tip.removeClassName('in')
			$tip.up('body') !== undefined ? $tip.remove() : ''
			this.$element.fire('bootstrap:hidden')
		}
		
		return this
	}
	
	, fixTitle: function () {
		var $e = this.$element
		if ($e.readAttribute('title') || typeof($e.readAttribute('data-original-title')) != 'string') {
			$e.writeAttribute('data-original-title', $e.readAttribute('title') || '').writeAttribute('title',null)
		}
	}
	
	, hasContent: function () {
		return this.getTitle()
	}
	, getPosition: function () {
		var el = this.$element
		var obj = {}
		if(typeof el.getBoundingClientRect == 'function'){
			Object.extend(obj,el.getBoundingClientRect())
		} else {
			Object.extend(obj,{
				width: el.offsetWidth
				, height: el.offsetHeight
			})
		}
		return Object.extend(obj,el.positionedOffset())
	}
	
	, getTitle: function () {
		var title
		, $e = this.$element
		, o = this.options
		
		title = $e.readAttribute('data-original-title')
		|| (typeof o.title == 'function' ? o.title.call($e) :  o.title)
		
		return title
	}
	
	, tip: function () {
		return this.$tip = this.$tip || this.options.template
	}
	, arrow: function(){
		return this.$arrow = this.$arrow || this.tip().select(".tooltip-arrow")
	}
	, validate: function () {
		if (!this.$element[0].parentNode) {
			this.hide()
			this.$element = null
			this.options = null
		}
	}
	, enable: function () {
		this.enabled = true
	}
	, disable: function () {
		this.enabled = false
	}
	, toggleEnabled: function () {
		this.enabled = !this.enabled
	}
	, toggle: function (e) {
		this.tip().hasClassName('in') ? this.hide() : this.show()		
	}
	, destroy: function () {
		this.hide()
		var eventIn, eventOut;
		this.options.trigger.split(' ').each(function(tr){
			if(tr == 'click') {
				this.$element.stopObserving('click')
			} else if (tr != 'manual') {
				eventIn = tr == 'hover' ? 'mouseenter' : 'focus'
				eventOut = tr == 'hover' ? 'mouseleave' : 'blur'
				this.$element.stopObserving(eventIn)
				this.$element.stopObserving(eventOut)
			}
		},this)
	}
});

//BootStrap.Popover
BootStrap.Popover = Class.create(BootStrap.Tooltip,{
	initialize : function ($super,element, options) {
		element.store('bootstrap:popover',this)
		$super(element,{subclass:true});
		Object.extend(this.options,{
			placement: 'right'
			, trigger: 'click'
			, content: ''
			, template: new Element('div',{'class':'popover'}).insert(new Element('div',{'class':'arrow'})).insert(new Element('h3',{'class':'popover-title'})).insert(new Element('div',{'class':'popover-content'}))
		});
		if(options && options.template && Object.isString(options.template))
		{
			var t = new Element('div').update(options.template);
			options.template = t.down();
		}
		Object.extend(this.options,options)
		this.init('popover',element,this.options)
	}
	, setContent: function () {
		var $tip = this.tip()
		, title = this.getTitle()
		, content = this.getContent()
		
		$tip.select('.popover-title').length > 0 ? $tip.select('.popover-title')[0].update(title) : ''
		$tip.select('.popover-content').length > 0 ? $tip.select('.popover-content')[0].update(content) : ''
		
		$tip.removeClassName('fade top bottom left right in')
	}
	
	, hasContent: function () {
		return this.getTitle() || this.getContent()
	}
	
	, getContent: function () {
		var content
		, $e = this.$element
		, o = this.options
		
		content = (typeof o.content == 'function' ? o.content.call($e[0]) :  o.content)
		|| $e.readAttribute('data-content')
		
		return content
	}
	
	, tip: function () {
		if (!this.$tip) {
			this.$tip = this.options.template
		}
		return this.$tip
	}
	
	, destroy: function ($super) {
		$super()
		this.hide()
		this.$element.stopObserving(this.options.trigger)
	}
});

//BootStrap.Scrollspy
BootStrap.ScrollSpy = Class.create({

	initialize : function(element, options) {
		element = $(element)
		element.store('bootstrap:scrollspy',this)
		//defaults
		this.options = {
			offset: 30
		}
		if(element.hasAttribute('data-target'))
		{
			this.options.target = element.readAttribute('data-target')
		}
		var $element = element.match('body') ? window : element
		var href

		Object.extend(this.options, options)
		this.$scrollElement = $element.observe('scroll', this.process.bind(this))
		this.selector = (this.options.target
			|| ((href = element.readAttribute('href')) && href.replace(/.*(?=#[^\s]+$)/, '')) //strip for ie7
			|| '') + ' .nav li > a'
		this.$body = $$('body').first();
		this.refresh()
		this.process()
	},
	refresh: function () {
		var self = this
		var $targets

		this.offsets = []
		this.targets = []

		$targets = this.$body.select(this.selector).map(function(t) {
			var $el = t
			var href = $el.readAttribute('data-target') || $el.readAttribute('href')
			var $href = /^#\w/.test(href) && $$(href).first()
			return ( $href
				&& [ $href.viewportOffset().top - $href.getHeight() + ((this.$scrollElement != window) && this.$scrollElement.cumulativeScrollOffset().top), href ] ) || null
		},this).without(false,null)
		.sort(function (a, b) { return a - b })
		.each(function(v){
			this.offsets.push(v[0])
			this.targets.push(v[1])
		},this)
	},
	process: function () {
		var scrollTop = this.$scrollElement.cumulativeScrollOffset().top + this.options.offset
		var scrollHeight = this.$scrollElement.scrollHeight || this.$body.scrollHeight
		var maxScroll = scrollHeight - this.$scrollElement.getHeight()
		var offsets = this.offsets
		var targets = this.targets
		var activeTarget = this.activeTarget
		var i

		if (scrollTop >= maxScroll) {
			return activeTarget != (i = targets.last()) && this.activate ( i )
		}

		for (i = offsets.length; i--;) {
			activeTarget != targets[i]
				&& scrollTop >= offsets[i]
				&& (!offsets[i + 1] || scrollTop <= offsets[i + 1])
				&& this.activate( targets[i] )
		}
	},
	activate: function (target) {
		var active
		, selector

		this.activeTarget = target

		$$(this.options.target).length > 0 ? $$(this.options.target).first().select('.active').invoke('removeClassName','active') : '';

		selector = this.selector
		+ '[data-target="' + target + '"],'
		+ this.selector + '[href="' + target + '"]'

		active = $$(selector).first().up('li').addClassName('active')

		if (active.up('.dropdown-menu') !== undefined){
			active = active.up('li.dropdown').addClassName('active')
		}

		active.fire('bootstrap:activate')
	}

});


Event.observe(window,'load', function () {
	$$('[data-spy="scroll"]').each(function(element) {
		new BootStrap.ScrollSpy(element)
	})
})

//BootStrap.Tab
BootStrap.Tab = Class.create({
	initialize : function (element) {
		element.store('bootstrap:tab',this)
		this.element = $(element)
	}
	, show: function () {
		var $this = this.element
		, $ul = $this.up('ul:not(.dropdown-menu)')
		, selector = $this.readAttribute('data-target')
		, previous
		, $target
		, e


		if (!selector) {
			selector = $this.readAttribute('href')
			selector = selector && selector.replace(/.*(?=#[^\s]*$)/, '') //strip for ie7
		}
		
		if ( $this.up('li') !== undefined && $this.up('li').hasClassName('active') ) return
		
		previous = $ul !== undefined ? $ul.select('.active:last a')[0] : null
		
		var showEvent = $this.fire('bootstrap:show',{'relatedTarget' : previous})

		if(showEvent.defaultPrevented) return
		
		$target = $$(selector)[0]

		this.activate($this.up('li'), $ul)
		this.activate($target, $target !== undefined ? $target.up() : undefined , function () {
			$this.fire('bootstrap:shown',{'relatedTarget':previous})
		})
	}
	
	, activate: function ( element, container, callback) {
		var $active = container !== undefined ? container.select('> .active')[0] : undefined
		var transitionCSS = callback && BootStrap.handleeffects == 'css' && $active !== undefined && $active.hasClassName('fade')
		var transitionEffect = BootStrap.handleeffects == 'effect' && typeof Effect !== 'undefined' && typeof Effect.Fade !== 'undefined'
		
		function next() {
			$active !== undefined ? $active
			.removeClassName('active')
			.select('> .dropdown-menu > .active')
			.invoke('removeClassName','active') : ''
			
			element !== undefined ? element.addClassName('active') : ''
			
			
			if (transitionCSS) {
				element.offsetWidth // reflow for transition
				element.addClassName('in')
			} else if (transitionEffect) {
				new Effect.Appear(element,{duration:0.3,afterFinish:function(){
					element.addClassName('in')
				}})
			} else {
				element !== undefined ? element.removeClassName('fade') : ''
			}

			if ( element !== undefined && element.up('.dropdown-menu') ) {
				element.up('li.dropdown').addClassName('active')
			}
			
			callback && callback()
		}
		
		if(transitionCSS){
			$active.observe(BootStrap.transitionendevent,function(e){
				next(e)
				this.stopObserving(BootStrap.transitionendevent)
			});
			$active !== undefined ? $active.removeClassName('in') : ''
		} else if (transitionEffect){
			if($active !== undefined && $active.hasClassName('in') && $active.hasClassName('fade')){
				new Effect.Fade($active,{duration:0.3,afterFinish:function(){
					$active.removeClassName('in')
					next()
				}})
			}
			else{
				next()
			}
		} else {
			next()
			$active !== undefined ? $active.removeClassName('in') : ''
		}
		
	}
});

//BootStrap.Typeahead
BootStrap.Typeahead = Class.create({

	initialize: function(element, options) {
		this.$element = $(element)
		this.$element.store('bootstrap:typeahead',this)

		this.options = {
			source: []
			, items: 8
			, menu: new Element('ul',{'class':'typeahead dropdown-menu'})
			, item: new Element('li').update(new Element('a',{'href':'#'}))
			, minLength: 1
		}

		this.options.items = (this.$element.readAttribute('data-items') ? this.$element.readAttribute('data-items') : this.options.items)
		this.options.source = (this.$element.readAttribute('data-source') ? this.$element.readAttribute('data-source').evalJSON(true) : this.options.source)
		
		
		Object.extend(this.options, options)
		this.matcher = this.options.matcher || this.matcher
		this.sorter = this.options.sorter || this.sorter
		this.highlighter = this.options.highlighter || this.highlighter
		this.updater = this.options.updater || this.updater
		this.source = this.options.source
		this.$menu = this.options.menu
		this.shown = false
		this.listen()
	}
	, select: function () {
		var val = this.$menu.down('.active').readAttribute('data-value')
		this.$element.setValue(this.updater(val))
		
		this.$element.fire('bootstrap:change')
		
		return this.hide()
	}
	, updater: function (item) {
		return item
	}
	, show: function () {
		var pos = Object.extend({}, this.$element.positionedOffset())
		Object.extend(pos, {
			height: this.$element.offsetHeight
		})
		
		this.$menu.setStyle({
				'top': (pos.top + pos.height)+'px'
				, 'left': (pos.left)+'px'
				, 'display' : 'block'
			})
		this.$element.insert({'after':this.$menu})
		
		this.shown = true
		return this
	}
	, hide: function () {
		this.$menu.hide()
		this.shown = false
		return this
	}
	, lookup: function (event) {
		var items
		
		this.query = this.$element.getValue()
		
		if (!this.query || this.query.length < this.options.minLength) {
			return this.shown ? this.hide() : this
		}
		
		items = Object.isFunction(this.source) ? this.source(this.query, this.process.bind(this)) : this.source
		
		return items ? this.process(items) : this
	}
	, process: function (items) {
		
		items = items.findAll(this.matcher,this)
		
		items = this.sorter(items)
		
		if (!items.length) {
			return this.shown ? this.hide() : this
		}
		
		return this.render(items.slice(0, this.options.items)).show()
	}
	, matcher: function (item) {
		return ~item.toLowerCase().indexOf(this.query.toLowerCase())
	}

	, sorter: function (items) {
		var beginswith = []
		, caseSensitive = []
		, caseInsensitive = []
		, item
		
		while (item = items.shift()) {
			if (!item.toLowerCase().indexOf(this.query.toLowerCase())) beginswith.push(item)
			else if (~item.indexOf(this.query)) caseSensitive.push(item)
			else caseInsensitive.push(item)
		}
		
		return beginswith.concat(caseSensitive, caseInsensitive)
	}
	, highlighter: function (item) {
		var query = this.query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
		return item.replace(new RegExp('(' + query + ')', 'ig'), function ($1, match) {
			return '<strong>' + match + '</strong>'
		})
	}
	, render: function (items) {
		
		items = items.map(function(item){
			var i = this.options.item.clone(true).writeAttribute('data-value',item)
			i.down('a').update(this.highlighter(item))
			return i
		},this)
		
		items.first().addClassName('active')
		this.$menu.update()
		items.each(function(i){
			this.$menu.insert(i)
		},this)
		return this
	}
	, next: function (event) {
		var active = this.$menu.down('.active').removeClassName('active')
		, next = active.next()
		
		if (next === undefined) {
			next = this.$menu.down('li')
		}
		
		next.addClassName('active')
	}
	, prev: function (event) {
		var active = this.$menu.down('.active').removeClassName('active')
		, prev = active.previous()
		
		if (prev === undefined) {
			prev = this.$menu.select('li').last()
		}
		
		prev.addClassName('active')
	}
	, listen: function () {
		this.$element
			.observe('focus',     this.focus.bind(this))
			.observe('blur',      this.blur.bind(this))
			.observe('keypress',  this.keypress.bind(this))
			.observe('keyup',     this.keyup.bind(this))
		
		if (this.eventSupported('keydown')) {
			this.$element.observe('keydown',this.keydown.bind(this))
		}
		
		this.$menu.observe('click', this.click.bind(this))
		this.$menu.on('mouseover', 'li', this.mouseenter.bind(this))
		this.$menu.on('mouseout', 'li', this.mouseleave.bind(this))
	}
	, eventSupported: function(eventName) {
		var isSupported = ('on'+eventName) in this.$element
		if (!isSupported) {
			this.$element.writeAttribute(eventName, 'return;')
			isSupported = typeof this.$element[eventName] === 'function'
		}
		return isSupported
	}
	, move: function (e) {
		if (!this.shown) return
		
		switch(e.keyCode) {
			case Event.KEY_TAB: 
			case Event.KEY_RETURN: 
			case Event.KEY_ESC: 
				e.preventDefault()
				break
			
			case Event.KEY_UP: 
				e.preventDefault()
				this.prev()
				break
			
			case Event.KEY_DOWN: 
				e.preventDefault()
				this.next()
				break
		}
		
		e.stopPropagation()
	}
	, keydown: function (e) {
		this.suppressKeyPressRepeat = ~[40,38,9,13,27].indexOf(e.keyCode)
		this.move(e)
	}
	, keypress: function (e) {
		if (this.suppressKeyPressRepeat) return
		this.move(e)
	}
	, keyup: function (e) {
		switch(e.keyCode) {
			case Event.KEY_DOWN:
			case Event.KEY_UP:
			case 16: // shift
			case 17: // ctrl
			case 18: // alt
				break
			
			case Event.KEY_TAB:
			case Event.KEY_RETURN:
				if (!this.shown) return
				this.select()
				break
			
			case Event.KEY_ESC:
				if (!this.shown) return
				this.hide()
				break
			
			default:
				this.lookup()
		}
		
		e.stopPropagation()
		e.preventDefault()
	}
	, focus: function (e) {
		this.focused = true
	}
	, blur: function (e) {
		this.focused = false
		if (!this.mousedover && this.shown) this.hide()
	}
	, click: function (e) {
		e.stopPropagation()
		e.preventDefault()
		this.select()
		this.$element.focus()
	}
	, mouseenter: function (e) {
		this.mousedover = true
		this.$menu.select('.active').invoke('removeClassName','active')
		e.findElement('li').addClassName('active')
		e.stopPropagation()
	}
	, mouseleave: function (e) {
		this.mousedover = false
		if (!this.focused && this.shown) this.hide()
		e.stopPropagation()
	}
});



document.observe('dom:loaded',function(){


	//BootStrap.Alert

	$$('.alert [data-dismiss="alert"]').each(function(i){
		new BootStrap.Alert(i)
	})

	//BootStrap.Button

	$$("[data-toggle^=button]").invoke("observe","click",function(e){
		var $btn = e.findElement()
		if(!$btn.hasClassName('btn')) $btn = $btn.up('.btn')
		new BootStrap.Button($btn,'toggle')
	});

	//BootStrap.Carousel

	document.on('click','[data-slide], [data-slide-to]',function(e){
		var $this = e.findElement(), href
		, $target = $$($this.readAttribute('data-target') || (href = $this.readAttribute('href')) && href.replace(/.*(?=#[^\s]+$)/, '')).first() //strip for ie7
		, options = Object.extend({})
		, to = $this.readAttribute('data-slide')
		, slideIndex
		
		to ? $target.retrieve('bootstrap:carousel')[to]() : ''

		if ($this.hasAttribute('data-slide-to')) {
			slideIndex = $this.readAttribute('data-slide-to')
			$target.retrieve('bootstrap:carousel').pause().to(slideIndex).cycle()
		}
		
		e.stop()
	});

	//BootStrap.Collapse

	$$('[data-toggle="collapse"]').each(function(e){
		var href = e.readAttribute('href');
		href = e.hasAttribute('href') ? href.replace(/.*(?=#[^\s]+$)/, '') : null
		var target = e.readAttribute('data-target') || href
		, options = {toggle : false}
		if(e.hasAttribute('data-parent')){
			options.parent = e.readAttribute('data-parent').replace('#','')
		}
		target = $$(target).first()
		if(target.hasClassName('in')){
			e.addClassName('collapsed')
		} else {
			e.removeClassName('collapsed')
		}
		new BootStrap.Collapse(target,options)
	});

	document.on('click','[data-toggle="collapse"]',function(e,targetelement){
		var href = targetelement.readAttribute('href');
		href = targetelement.hasAttribute('href') ? href.replace(/.*(?=#[^\s]+$)/, '') : null
		var target = targetelement.readAttribute('data-target') || e.preventDefault() || href
		$$(target).first().retrieve('bootstrap:collapse').toggle();
	});

	//BootStrap.Dropdown
/* APPLY TO STANDARD DROPDOWN ELEMENTS
 * =================================== */

	document.observe('click',BootStrap.Dropdown.prototype.clearMenus)
	$$('.dropdown form').invoke('observe','click',function(e){
		e.stop();
	});
	$$('[data-toggle=dropdown]').invoke('observe','click',BootStrap.Dropdown.prototype.toggle)
	$$('[data-toggle=dropdown]'+', [role=menu]').invoke('observe','keydown',BootStrap.Dropdown.prototype.keydown)

	//BootStrap.Modal

	$$("[data-toggle='modal']").invoke("observe","click",function(e){
		var target = this.readAttribute("data-target") || (this.href && this.href.replace(/.*(?=#[^\s]+$)/,'').replace(/#/,''));
		var options = {};
		if($(target) !== undefined) {
			target = $(target);
			if(!/#/.test(this.href)) {
				options.remote = this.href;
			}
			new BootStrap.Modal($(target),options);
		}
		e.stop();
	});

	//BootStrap.Tab

	$$('[data-toggle="tab"], [data-toggle="pill"]').invoke('observe','click',function(e){
		e.preventDefault();
		new BootStrap.Tab(this).show()
	});

	//BootStrap.Typeahead

	$$('[data-provide="typeahead"]').each(function(i){
		new BootStrap.Typeahead(i)
	});

});