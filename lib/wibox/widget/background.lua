---------------------------------------------------------------------------
-- @author Uli Schlachter
-- @copyright 2010 Uli Schlachter
-- @release @AWESOME_VERSION@
-- @classmod wibox.widget.background
---------------------------------------------------------------------------

local base = require("wibox.widget.base")
local color = require("gears.color")
local surface = require("gears.surface")
local beautiful = require("beautiful")
local cairo = require("lgi").cairo
local setmetatable = setmetatable
local pairs = pairs
local type = type
local unpack = unpack or table.unpack

local background = { mt = {} }

--- Draw this widget
function background:draw(context, cr, width, height)
    if not self.widget or not self.widget.visible then
        return
    end

    -- Keep the shape path in case there is a border
    self._path = nil

    if self._shape then
        -- Only add the offset if there is something to draw
        local offset = ((self._shape_border_width and self._shape_border_color)
            and self._shape_border_width or 0) / 2

        cr:translate(offset, offset)
        self._shape(cr, width - 2*offset, height - 2*offset, unpack(self._shape_args or {}))
        cr:translate(-offset, -offset)
        self._path = cr:copy_path()
        cr:clip()
    end

    if self.background then
        cr:set_source(self.background)
        cr:paint()
    end
    if self.bgimage then
        local pattern = cairo.Pattern.create_for_surface(self.bgimage)
        cr:set_source(pattern)
        cr:paint()
    end

end

-- Draw the border
function background:after_draw_children(context, cr, width, height)
    -- Draw the border
    if self._path and self._shape_border_width and self._shape_border_width > 0 then
        cr:append_path(self._path)
        cr:set_source(color(self._shape_border_color or self.foreground or beautiful.fg_normal))

        cr:set_line_width(self._shape_border_width)
        cr:stroke()
        self._path = nil
    end
end

--- Prepare drawing the children of this widget
function background:before_draw_children(context, cr, width, height)
    if self.foreground then
        cr:set_source(self.foreground)
    end
end

--- Layout this widget
function background:layout(context, width, height)
    if self.widget then
        return { base.place_widget_at(self.widget, 0, 0, width, height) }
    end
end

--- Fit this widget into the given area
function background:fit(context, width, height)
    if not self.widget then
        return 0, 0
    end

    return base.fit_widget(self, context, self.widget, width, height)
end

--- Set the widget that is drawn on top of the background
function background:set_widget(widget)
    if widget then
        base.check_widget(widget)
    end
    self.widget = widget
    self:emit_signal("widget::layout_changed")
end

--- Get the number of children element
-- @treturn table The children
function background:get_children()
    return {self.widget}
end

--- Set the background to use
function background:set_bg(bg)
    if bg then
        self.background = color(bg)
    else
        self.background = nil
    end
    self:emit_signal("widget::redraw_needed")
end

--- Set the foreground to use
function background:set_fg(fg)
    if fg then
        self.foreground = color(fg)
    else
        self.foreground = nil
    end
    self:emit_signal("widget::redraw_needed")
end

--- Set the background shape
-- @param shape A function taking a context, width and height as arguments
-- Any other arguments will be passed to the shape function
function background:set_shape(shape, ...)
    self._shape = shape
    self._shape_args = {...}
    self:emit_signal("widget::redraw_needed")
end

--- When a `shape` is set, also draw a border
-- @tparam number width The border width
function background:set_shape_border_width(width)
    self._shape_border_width = width
    self:emit_signal("widget::redraw_needed")
end

--- When a `shape` is set, also draw a border
-- @param[opt=self.foreground] fg The border color, pattern or gradient
function background:set_shape_border_color(fg)
    self._shape_border_color = fg
    self:emit_signal("widget::redraw_needed")
end

--- Set the background image to use
function background:set_bgimage(image)
    self.bgimage = surface.load(image)
    self:emit_signal("widget::redraw_needed")
end

--- Returns a new background layout. A background layout applies a background
-- and foreground color to another widget.
-- @param[opt] widget The widget to display.
-- @param[opt] bg The background to use for that widget.
-- @param[opt] shape A `gears.shape` compatible shape function
local function new(widget, bg, shape)
    local ret = base.make_widget()

    for k, v in pairs(background) do
        if type(v) == "function" then
            ret[k] = v
        end
    end

    ret._shape = shape

    ret:set_widget(widget)
    ret:set_bg(bg)

    return ret
end

function background.mt:__call(...)
    return new(...)
end

return setmetatable(background, background.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
