Gooey.ListView.KeyboardMap = Gooey.KeyboardMap ()

Gooey.ListView.KeyboardMap:Register (KEY_PAGEUP,
	function (self, key, ctrl, shift, alt)
		self.VScroll:ScrollAnimated (-self.ScrollableViewController:GetViewHeight ())
		return true
	end
)

Gooey.ListView.KeyboardMap:Register (KEY_PAGEDOWN,
	function (self, key, ctrl, shift, alt)
		self.VScroll:ScrollAnimated (self.ScrollableViewController:GetViewHeight ())
		return true
	end
)

Gooey.ListView.KeyboardMap:Register (KEY_HOME,
	function (self, key, ctrl, shift, alt)
		self.VScroll:SetViewOffset (0, true)
		return true
	end
)

Gooey.ListView.KeyboardMap:Register (KEY_END,
	function (self, key, ctrl, shift, alt)
		self.VScroll:SetViewOffset (self.ScrollableViewController:GetContentHeight (), true)
		return true
	end
)

Gooey.ListView.KeyboardMap:Register (KEY_A,
	function (self, key, ctrl, shift, alt)
		if not ctrl then return end
		
		for listViewItem in self:GetItemEnumerator () do
			self.SelectionController:AddToSelection (listViewItem)
		end
		return true
	end
)