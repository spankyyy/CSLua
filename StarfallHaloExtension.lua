SF.Modules.halo = {injected = {init = function(instance)
    local ounwrap = instance.UnwrapObject
    instance.env.halo = {
      add = function(ents, color, blurX, blurY, passes, additive, ignoreZ)
        ents = instance.Unsanitize(ents)
        halo.Add(ents, color, blurX, blurY, passes, additive, ignoreZ)
      end,
      render = halo.Render,
      renderedEntity = halo.RenderedEntity
    }
    SF.hookAdd("PreDrawHalos", nil, function(instance)
      return true, {} 
    end)
end}}
