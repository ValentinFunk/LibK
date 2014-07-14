// Alphafix method by MDave

local PANEL = {}

function PANEL:Init( )

end

function PANEL:Paint(w, h)
	-- Render model
	do 
		render.PushRenderTarget( modelRT )

			render.Clear( 0,0,0, 255 )
			render.ClearDepth()

			cam.Start( view )

				-- Fill RT where we draw
				stencil.Clear()
				stencil.Enable( true )

				stencil.ReferenceValue( 1 )

				stencil.PassOperation( STENCIL_REPLACE )
				stencil.FailOperation( STENCIL_KEEP )
				stencil.ZFailOperation( STENCIL_KEEP )

				stencil.CompareFunction( STENCIL_ALWAYS )

				-- Render model
				render.OverrideAlphaWriteEnable( true, false )
					
					cModel:DrawModel()
					cModel:Remove()

				render.OverrideAlphaWriteEnable( false )
		
				-- Hack to make the RT transparent
				stencil.CompareFunction( STENCIL_NOTEQUAL )
				stencil.ClearBuffers( 0,0,0, 0 )

				stencil.Enable( false )

			cam.End()
		render.PopRenderTarget()
	end
end