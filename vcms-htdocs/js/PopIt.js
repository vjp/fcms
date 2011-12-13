//Copyright (c) 2009 Michael Harris michael@harrisdev.net
//
//Permission is hereby granted, free of charge, to any person
//obtaining a copy of this software and associated documentation
//files (the "Software"), to deal in the Software without
//restriction, including without limitation the rights to use,
//copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the
//Software is furnished to do so, subject to the following
//conditions:
//
//The above copyright notice and this permission notice shall be
//included in all copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//OTHER DEALINGS IN THE SOFTWARE.


//If you do choose to use this,
//please drop me an email at michael@harrisdev.net
//I would like to see where this ends up :)

var popIts =
{
	activePopIts: {},
	closeAll: function()
	{
		Object.keys(popIts.activePopIts).each(function(key)
		{
			popIts.activePopIts[key].close();
		});
	}
};

var PopIt = Class.create();
PopIt.version = 0.4;

PopIt.prototype = {
    initialize: function(content, params)
    {
		//requirements
		if (typeof(Prototype) == 'undefined' || (parseFloat(Prototype.Version.split(".")[0] + "." + Prototype.Version.split(".")[1]) < 1.6)) 
		{
			throw (new Error('PopIt: requires Prototype 1.6.0+'));
		}
		if (typeof(Effect) == 'undefined') 
		{
			throw (new Error('PopIt: requires Script.aculo.us, specifically Effects'));
		}
		if (typeof(Draggable) == 'undefined') 
		{
			throw (new Error('PopIt: requires Script.aculo.us, specifically DragDrop'));
		}
		
		var defaultParams = 
		{
			id: false,
			content: content,
			title: '&nbsp;', //the window title
			parent: $(document.body), //what element to insert the PopIt into
			scrollElement: document.documentElement && document.documentElement.scrollTop ? document.documentElement : document.body,
			height: 150, //the height of the PopIt
			width: 200, // the width of the PopIt
			shimOpacity: 0.9, // the opacity to use for the various cover divs
			isModal: false, // if he window is a modal dialog or not
			isDraggable: true, // if dragging is enabled
			isResizable: true, // if resizing is enabled
			isMinimizable: true, // if minimize functions are enabled
			isMaximizable: true, // if maximize functions are enabled
			isClosable: true, // if closing functions are enabled
			escapeClosesPopIt: true, // if pressing the escape key closes all PopIts
			isUrl: false, // if content type is a url and an iframe should be used
			offsetTop: 20, //the amount of px to add to the top of the PopIt
			effectDuration: 0.5, //the duration of the various effects that happen with the PopIt
			className: "", //the base classname to use for the PopIt 
			beforeClose: false,
			afterClose: false,
			beforeShow: false,
			afterShow: false
		}
		
		Object.extend(this, defaultParams);
		Object.extend(this, params);
		
		if (this.id && $(this.id))
		{
			Object.extend(this, popIts.activePopIts[this.id]);
			return;
		}
		
		//TODO browser compatibility
		//todo more css
		this.generatePopIt();
		
		this.centerHandler = this.center.bindAsEventListener(this);
		Event.observe(window, 'resize', this.centerHandler);
		if (this.escapeClosesPopIt) 
		{
			this.keyDownHandler = this.keyDown.bindAsEventListener(this);
			Event.observe(document, 'keydown', this.keyDownHandler);
		}
	},
	
	keyDown: function(event)
	{
		//note this will not work for is url content while focused inside the content due to the iframe 
		if (event.keyCode == Event.KEY_ESC)
		{
			this.close(event);
		}
	},
	
	
	refreshDragDrop: function()
	{
		if (this.isDraggable) 
		{
			this.titleDrag = new Draggable(this.popIt, 
			{
				handle: this.titleBarDiv,
				onStart: function(draggable, event)
				{
					if (this.isUrl) 
					{
						this.createShim();
						this.contentDiv.insert(this.shim);
						this.shim.show();
					}
				}.bind(this),
				onEnd: function(draggable, event)
				{
					if (this.isUrl) 
					{
						this.shim.hide();
					}
					if (parseInt(this.popIt.getStyle('top'), 10) < 0)
					{
						this.popIt.setStyle(
						{
							top: 0
						});
					}
					if (parseInt(this.popIt.getStyle('left'), 10) < 0)
					{
						this.popIt.setStyle(
						{
							left: 0
						});
					}

				}.bind(this)
			});
		}
		
		if (!this.isResizable) 
		{
			return;
		}
		
		this.topResizeDrag = new Draggable(this.topResizeDiv, 
		{
			constraint: 'vertical',
			onStart: function(draggable, event)
			{
				this.origY = event.pointerY() - this.padBottom;
				this.showDragShim(draggable, 'TB');
			}.bind(this),
			onEnd: function(draggable, event)
			{
				var y = event.pointerY() - this.padBottom;
				this.height = this.popIt.getHeight() + (this.origY - y);
				if (y < 10)
				{
					this.height += y;
					y = 10;
				}
				this.height -= this.padBottom;
				y += this.padBottom;
				
				var minHeight = parseInt(this.popIt.getStyle('min-height'), 10)
				if (this.height < minHeight) 
				{
					var dif = minHeight - this.height;
					this.height = minHeight; 
					y -= dif; 
				}

			    this.popIt.setStyle(
				{
					top: y + 'px',
					height: this.height + 'px'
				});
				this.topResizeDiv.setStyle(
				{
					bottom: '',
					top: ''
				});
				if (this.shim)			
				{
					this.shim.setStyle(
					{
						height: this.popIt.getHeight() + 'px'
					});
				}
				
				this.rightResizeDiv.setStyle(
				{
					height: this.popIt.getHeight() + 'px'
				});
				this.leftResizeDiv.setStyle(
				{
					height: this.popIt.getHeight() + 'px'
				});
				
				this.origY = null;
				this.hideDragShim(draggable);
			}.bind(this)
		});
		
		this.rightResizeDrag = new Draggable(this.rightResizeDiv, 
		{
			constraint: 'horizontal',
			onStart: function(draggable, event)
			{
				this.origX = event.pointerX();
				this.showDragShim(draggable, 'LR');
			}.bind(this),
			onEnd: function(draggable, event)
			{
				var x = event.pointerX();
				this.width = this.popIt.getWidth() + (x - this.origX);
				var parentWidth = this.parent.getWidth() - 10;
				if (x > parentWidth)
				{
					var sub = (parentWidth - x);
					x += sub;
					this.width += sub;
				}
				var minWidth = parseInt(this.popIt.getStyle('min-width'), 10)
				if (this.width < minWidth) 
				{
					var dif = minWidth - this.width;
					this.width = minWidth; 
					x -= dif; 
				}
								
				this.popIt.setStyle(
				{
					right: x + 'px',
					width: this.width + 'px'
				});
				this.rightResizeDiv.setStyle(
				{
					left: '',
					right: ''
				});
				
				this.origX = null;
				this.hideDragShim(draggable);
			}.bind(this)
		});
		
		this.bottomResizeDrag = new Draggable(this.bottomResizeDiv, 
		{
			constraint: 'vertical',
			onStart: function(draggable, event)
			{
				this.origY = event.pointerY() - this.scrollElement.scrollTop;
				this.showDragShim(draggable, 'TB');
			}.bind(this),
			onEnd: function(draggable, event)
			{
				var y = event.pointerY() - this.scrollElement.scrollTop;
				this.height = this.popIt.getHeight() + (y - this.origY);
				
				var parentHeight = this.parent.getHeight() - 10;
				if (y > parentHeight)
				{
					var sub = parentHeight - y; 
					y += sub;
					this.height += sub;
				}
				this.height -= this.padBottom;
				
				var minHeight = parseInt(this.popIt.getStyle('min-height'), 10)
				if (this.height < minHeight) 
				{
					var dif = minHeight - this.height;
					this.height = minHeight; 
					y -= dif; 
				}
				
				this.popIt.setStyle(
				{
					height: this.height + 'px'
				});
				this.bottomResizeDiv.setStyle(
				{
					bottom: '',
					top: ''
				});
				
				if (this.shim)			
				{
					this.shim.setStyle(
					{
						height: this.popIt.getHeight() + 'px'
					});
				}
				this.rightResizeDiv.setStyle(
				{
					height: this.popIt.getHeight() + 'px'
				});
				this.leftResizeDiv.setStyle(
				{
					height: this.popIt.getHeight() + 'px'
				});
				
				this.origY = null;
				this.hideDragShim(draggable);
			}.bind(this)
		});
		
		
		this.leftResizeDrag = new Draggable(this.leftResizeDiv, 
		{
			constraint: 'horizontal',
			onStart: function(draggable, event)
			{
				this.origX = event.pointerX();
				this.showDragShim(draggable, 'LR');
			}.bind(this),
			onEnd: function(draggable, event)
			{
				var x = event.pointerX();
				this.width = this.popIt.getWidth() + (this.origX - x);
				if (x < 10)
				{
					this.width += x - 10;
					x = 10;
				}
				var minWidth = parseInt(this.popIt.getStyle('min-width'), 10)
				if (this.width < minWidth) 
				{
					var dif = minWidth - this.width;
					this.width = minWidth; 
					x -= dif; 
				}
				
				this.width;
				x;
				this.popIt.setStyle(
				{
					left: x + 'px',
					width: this.width + 'px'
				});
				this.leftResizeDiv.setStyle(
				{
					right: '',
					left: ''
				});
				
				this.origX = null;
				this.hideDragShim(draggable);
			}.bind(this)
		});
	},

	createShim: function()
	{
		if (!this.shim)
		{
			this.shim = new Element('div', 
			{
				className: 'shim'
			}).setStyle(
				{
					height: this.popIt.getHeight() + 'px',
					opacity: this.shimOpacity
				});
		}
	},	
	showDragShim: function(draggable, LRTB)
	{
		this.createShim();
		this.popIt.insert(this.shim)
		draggable.element.addClassName('resizing' + LRTB);
		this.shim.show();
	},
	
	hideDragShim: function(draggable)
	{
		draggable.element.removeClassName('resizingLR');
		draggable.element.removeClassName('resizingTB');
		this.shim.hide();
	},
    
    generatePopIt: function()
    {
		if (this.beforeShow)
		{
			this.beforeShow();
		}
		this.popIt = new Element('div',
		{
			className: "popIt " + this.className
		}).setStyle(
			{
				top: (this.scrollElement.scrollTop + this.offsetTop) + 'px',
				width: this.width + 'px',
				height: this.height + 'px'
			});
		if (this.id) 
		{
			this.popIt.id = this.id;
		}
		else
		{
			this.id = this.popIt.identify();
		}
		popIts.activePopIts[this.id] = this;
		
		this.generateTitleBar()
		this.generateContentDiv();
		this.generateStatusBarDiv();			
		
		if (this.isModal) 
		{
			this.modalShim = new Element('div', 
			{
				className: 'ModalShim'
			}).setStyle(
			{
				height: this.scrollElement.scrollHeight + 'px',
				opacity: this.shimOpacity
			});
			this.modalShim.hide();
			this.parent.insert(this.modalShim);
			new Effect.Appear(this.modalShim, 
			{
				from: 0, 
				to: this.shimOpacity,
				duration: this.effectDuration
			});
		}
		this.popIt.hide();
		this.parent.insert(this.popIt);
		this.padBottom = parseInt(this.popIt.getStyle('padding-bottom'), 10);
		this.center();
		this.generateResizeElements();	
		new Effect.Appear(this.popIt, 
		{
			duration: this.effectDuration,
			afterFinish: function()
			{
				if (this.afterShow)
				{
					this.afterShow();
				}
			}.bind(this)
		});
		
		
		this.refreshDragDrop();
    },
	
	center: function()
	{
		var left = this.parent.getWidth() / 2;
		left = left - (this.popIt.getWidth() / 2);
		left += 'px';
		
		this.popIt.setStyle(
		{
			left: left
		});
	},
	
	generateResizeElements: function()
	{
		if (this.isDraggable) 
		{
			this.titleBarDiv.setStyle(
			{
				cursor: 'move'
			});
		}
		if (!this.isResizable)
		{
			return;
		}
		
		this.topResizeDiv = new Element('div', 
		{
			className: 'topResize'
		});
		this.popIt.insert(this.topResizeDiv);
		
		this.rightResizeDiv = new Element('div', 
		{
			className: 'rightResize'
		});
		this.popIt.insert(this.rightResizeDiv);

		this.bottomResizeDiv = new Element('div', 
		{
			className: 'bottomResize'
		});
		this.popIt.insert(this.bottomResizeDiv);
		
		this.leftResizeDiv = new Element('div', 
		{
			className: 'leftResize'
		});
		if (Prototype.Browser.IE) 
		{
			//this code causes a blink in firefox and isnt needed 
			//but ie wont size the resize elements correctly without it
			this.rightResizeDiv.setStyle(
			{
				height: this.popIt.getHeight() + 'px'
			});
			this.leftResizeDiv.setStyle(
			{
				height: this.popIt.getHeight() + 'px'
			});
		}
		
		this.popIt.insert(this.leftResizeDiv);
	},
	
	generateTitleBar: function()
	{
		this.titleBarDiv = 	new Element('div',
		{
			className: 'TitleBar'
		});

		if (this.isMaximizable) 
		{
			this.titleBarDiv.observe('dblclick', this.maximize.bindAsEventListener(this));
		}
				
		var controlsDiv = new Element('div',
		{
			className: 'Controls'
		});

		if (this.isMinimizable) 
		{
			this.minimizeButton = new Element('div', 
			{
				className: 'minimizeButton'
			}).observe('mousedown', this.minimize.bindAsEventListener(this));
			controlsDiv.insert(this.minimizeButton);
		}
		
		if (this.isMaximizable) 
		{
			this.maximizeButton = new Element('div', 
			{
				className: 'maximizeButton'
			}).observe('mousedown', this.maximize.bindAsEventListener(this));
			controlsDiv.insert(this.maximizeButton);
		}
		
		if (this.isClosable) 
		{
			this.closeButton = new Element('div', 
			{
				className: 'closeButton'
			}).observe('mousedown', this.close.bindAsEventListener(this));
			controlsDiv.insert(this.closeButton);
		}
		
		this.titleBarDiv.insert(controlsDiv);
					
		this.titleBarDiv.insert(this.title);
		
		this.popIt.insert(this.titleBarDiv);
	},
	
	generateContentDiv: function()
	{
		if (this.isUrl)
		{
			this.content = new Element('iframe', 
			{
				frameborder: 0, //required for ie
				className: 'ContentIFrame',
				src: this.content
			});
		}
		
		this.contentDiv = new Element('div',
		{
			className: 'Content'
		}).update(this.content);
		
		if (this.isUrl)
		{
			this.contentDiv.setStyle(
			{
				padding: '0'
			});
		}
		
		this.popIt.insert(this.contentDiv);
	},
	
	generateStatusBarDiv: function()
	{
		this.statusBarDiv = new Element('div', 
		{
			className: 'Status'
		});
		
		this.popIt.insert(this.statusBarDiv);
	},
	
	minimize: function(event)
	{
		if (event) 
		{
			event.stop();
		}
		this.isMinimized = !this.isMinimized;
		
		if (this.isMinimized)
		{
            this.popIt.setStyle(
			{
				minHeight: '0'
			});
			new Effect.Morph(this.popIt, 
            {
                style: 
                {
                    height: '0px'
                },
				duration: this.effectDuration
            });
			if (this.isResizable) 
			{
				this.topResizeDiv.hide();
				this.bottomResizeDiv.hide();
				this.rightResizeDiv.setStyle(
				{
					height: this.popIt.getStyle('paddingBottom')
				});
				this.leftResizeDiv.setStyle(
				{
					height: this.popIt.getStyle('paddingBottom')
				});
			}
			if (this.shim)
			{
				this.shim.setStyle(
				{
					height: this.popIt.getStyle('paddingBottom')
				});
			}
		}
		else
		{
			var height = this.height;

			if (this.isMaximized)
			{
				height = (this.parent.getHeight() - 5);
			}
			new Effect.Morph(this.popIt,
			{
				style:
				{
					height: height + 'px',
					minHeight: ''
				},
				duration: this.effectDuration
			});
			this.contentDiv.show();
			this.statusBarDiv.show();
			if (this.isResizable) 
			{
				this.topResizeDiv.show();
				this.bottomResizeDiv.show();
				this.rightResizeDiv.setStyle(
				{
					height: (height + this.padBottom) + 'px'
				});
				this.leftResizeDiv.setStyle(
				{
					height: (height + this.padBottom) + 'px'
				});
			}
			if (this.shim)
			{
				this.shim.setStyle(
				{
					height: (height + this.padBottom) + 'px'
				});
			}
		}
		
	},
	
	maximize: function(event)
	{
		if (event) 
		{
			event.stop();
			if (event.element().hasClassName('minimizeButton')) 
			{
				return;
			}
		}
		this.isMaximized = !this.isMaximized;
		this.isMinimized = true;//this will maximize the window into view gets toggled back in this.minimize();
		this.minimize(event);
		if (this.isMaximized) 
		{
			this.left = parseInt(this.popIt.getStyle('left'), 10);
			this.top = parseInt(this.popIt.getStyle('top'), 10);
			this.maximizeButton.addClassName('restoreButton');
			new Effect.Morph(this.popIt,
			{
				style:
				{
					left: '0px',
					top: this.scrollElement.scrollTop + 'px',
					width: (this.parent.getWidth() - 3) + 'px',
					height: (this.parent.getHeight() - this.padBottom - 3) + 'px'
				},
				duration: this.effectDuration
			});
			if (this.isResizable) 
			{
				this.topResizeDiv.hide();
				this.rightResizeDiv.hide();
				this.bottomResizeDiv.hide();
				this.leftResizeDiv.hide();
			}
		}
		else 
		{
			this.maximizeButton.removeClassName('restoreButton');
			new Effect.Morph(this.popIt,
			{
				style:
				{
					width: this.width + 'px',
					height: this.height +'px',
					left: this.left + 'px',
					top: this.top + 'px'
				},
				duration: this.effectDuration
			});
			if (this.isResizable)
			{
				this.topResizeDiv.show();
				this.rightResizeDiv.show();
				this.bottomResizeDiv.show();
				this.leftResizeDiv.show();
			}
		}
	},
	
	close: function(event)
	{
	    if (event) 
		{
			event.stop();
		}
		if (this.beforeClose) 
		{
			this.beforeClose();
		}
		if (this.modalShim) 
		{
			new Effect.Fade(this.modalShim,
			{
				duration: this.effectDuration
			});
		}
		if (this.shim)
		{
			this.shim.hide();
		}
		new Effect.Fade(this.popIt, 
		{
			duration: this.effectDuration, 
			afterFinish: function()
			{
				if (this.afterClose) 
				{
					this.afterClose();
				}
				this.destroy();
			}.bind(this)
			
		});
		
	},
	
	updateStatusText: function(text)
	{
		this.statusBarDiv.update(text);
	},
	
	destroy: function()
	{
		Event.stopObserving(window, 'resize', this.centerHandler);
		if (this.keyDownHandler) 
		{
			Event.stopObserving(window, 'keydown', this.keyDownHandler);
		}
		this.titleBarDiv.stopObserving();
		if (this.minimizeButton) 
		{
			this.minimizeButton.stopObserving();
		}
		if (this.maximizeButton) 
		{
			this.maximizeButton.stopObserving();
		}
		if (this.closeButton) 
		{
			this.closeButton.stopObserving();
		}
		
		if (this.titleDrag)
		{
			this.titleDrag.destroy();
		}
		if (this.topResizeDrag)
		{
			this.topResizeDrag.destroy();
		}
		if (this.rightResizeDrag)
		{
			this.rightResizeDrag.destroy();
		}
		if (this.bottomResizeDrag)
		{
			this.bottomResizeDrag.destroy();
		}
		if (this.leftResizeDrag)
		{
			this.leftResizeDrag.destroy();
		}

		if (this.modalShim && this.modalShim.parentNode) 
		{
			this.modalShim.remove();
		}

		if (this.popIt && this.popIt.parentNode) 
		{
			this.popIt.remove();
		}
				
		if (this.shim && this.shim.parentNode)
		{
			this.shim.remove();
		}	
		delete popIts.activePopIts[this.id];
	}
	
};