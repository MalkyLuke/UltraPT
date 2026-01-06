-- setquality.lua

Logger = require('helpers/Logger')
Var = require('helpers/Variables')
Config = {}
Cyberpunk = require('helpers/Cyberpunk')

function Config.SetVram(vram)

	Logger.info('Configuring vram for', vram, 'GB')

	Cyberpunk.SetOption('Rendering', 'DistantShadowsMaxBatchSize', '500')					-- vanilla 500
	Cyberpunk.SetOption('Rendering', 'DistantShadowsMaxTrianglesPerBatch', '400000')		-- vanilla 400000
	Cyberpunk.SetOption('Rendering', 'RainMapBatchMaxSize', '300')							-- vanilla 300
	Cyberpunk.SetOption('Rendering', 'RainMapBatchMaxTrianglesPerBatch', '200000')			-- vanilla 200000

	if vram == Var.vram.OFF then	
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Budget', '943718400')
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Reserve', '157286400')

		-- Cyberpunk.SetOption('World', 'StreamingTeleportMagSq', '4096.0')						-- vanilla 4096.0
		-- controlled by game based on RT mode, changing causes instability
		Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '64')				-- PT default is 256
		-- controlled by General Shadow Fixes
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateProxyNumMax', '192')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'RefitNumMax', '192')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceFactor', '1.0')

		Cyberpunk.SetOption('ResourceLoaderThrottler', 'FloodMinNonLoadingThreads', '2')
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'StreamMaxLoadingThreads', '2')
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'TrickleMaxLoadingThreads', '1')

		Cyberpunk.SetOption('Streaming', 'MaxNodesPerFrame', '300')
		Cyberpunk.SetOption('Streaming', 'EditorThrottledMaxNodesPerFrame', '500')
		
		return
	end

	if vram == Var.vram.GB4 then
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Budget', '943718400')
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Reserve', '157286400')

		-- Cyberpunk.SetOption('World', 'StreamingTeleportMagSq', '8192.0')						-- vanilla 4096.0
		-- controlled by game based on RT mode, changing causes instability
		Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '64')
		-- controlled by General Shadow Fixes
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateProxyNumMax', '256')			-- PT default is 256
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'RefitNumMax', '256')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceThreshold', '16.0')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceFactor', '1.0')

		Cyberpunk.SetOption('ResourceLoaderThrottler', 'FloodMinNonLoadingThreads', '2')		-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'StreamMaxLoadingThreads', '2')			-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'TrickleMaxLoadingThreads', '1')			-- vanilla 1

		Cyberpunk.SetOption('Streaming', 'MaxNodesPerFrame', '700')
		Cyberpunk.SetOption('Streaming', 'EditorThrottledMaxNodesPerFrame', '700')

		return
	end

	if vram == Var.vram.GB10 then
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Budget', '943718400')
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Reserve', '157286400')

		-- Cyberpunk.SetOption('World', 'StreamingTeleportMagSq', '8192.0')						-- vanilla 4096.0
		-- controlled by game based on RT mode, changing causes instability
		if Var.settings.mode == Var.mode.Raster or Var.settings.mode == Var.mode.RTOnly or Var.settings.mode == Var.mode.RT_PT then
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '64')
		else
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '80')
		end
		-- controlled by General Shadow Fixes
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateProxyNumMax', '384')			-- PT default is 256	
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'RefitNumMax', '384')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceThreshold', '24.0')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceFactor', '1.5')

		Cyberpunk.SetOption('ResourceLoaderThrottler', 'FloodMinNonLoadingThreads', '3')		-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'StreamMaxLoadingThreads', '1')			-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'TrickleMaxLoadingThreads', '1')			-- vanilla 1

		Cyberpunk.SetOption('Streaming', 'MaxNodesPerFrame', '800')
		Cyberpunk.SetOption('Streaming', 'EditorThrottledMaxNodesPerFrame', '800')

		return
	end

	if vram == Var.vram.GB16 then
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Budget', '1415577600')
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Reserve', '268435456')

		-- Cyberpunk.SetOption('World', 'StreamingTeleportMagSq', '8192.0')						-- vanilla 4096.0
		-- controlled by game based on RT mode, changing causes instability
		if Var.settings.mode == Var.mode.Raster or Var.settings.mode == Var.mode.RTOnly or Var.settings.mode == Var.mode.RT_PT then
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '64')
		else
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '112')
		end
		-- controlled by General Shadow Fixes
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateProxyNumMax', '512')			-- PT default is 256	
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'RefitNumMax', '512')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceThreshold', '30.0')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceFactor', '2.0')

		Cyberpunk.SetOption('ResourceLoaderThrottler', 'FloodMinNonLoadingThreads', '4')		-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'StreamMaxLoadingThreads', '1')			-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'TrickleMaxLoadingThreads', '1')			-- vanilla 1

		Cyberpunk.SetOption('Streaming', 'MaxNodesPerFrame', '800')
		Cyberpunk.SetOption('Streaming', 'EditorThrottledMaxNodesPerFrame', '800')

		return
	end

	if vram == Var.vram.GB20 then
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Budget', '1887436800')
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Reserve', '314572800')

		-- Cyberpunk.SetOption('World', 'StreamingTeleportMagSq', '8192.0')						-- vanilla 4096.0
		-- controlled by game based on RT mode, changing causes instability
		if Var.settings.mode == Var.mode.Raster or Var.settings.mode == Var.mode.RTOnly or Var.settings.mode == Var.mode.RT_PT then
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '64')
		else
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '128')
		end
		-- controlled by General Shadow Fixes
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateProxyNumMax', '512')			-- PT default is 256	
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'RefitNumMax', '512')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceThreshold', '30.0')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceFactor', '2.0')

		Cyberpunk.SetOption('ResourceLoaderThrottler', 'FloodMinNonLoadingThreads', '6')		-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'StreamMaxLoadingThreads', '1')			-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'TrickleMaxLoadingThreads', '1')			-- vanilla 1

		Cyberpunk.SetOption('Streaming', 'MaxNodesPerFrame', '800')
		Cyberpunk.SetOption('Streaming', 'EditorThrottledMaxNodesPerFrame', '800')

		return
	end
	
	if vram == Var.vram.AUTO then
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Budget', '943718400')
		Cyberpunk.SetOption('RayTracing/BlasCache', 'Reserve', '157286400')

		-- Cyberpunk.SetOption('World', 'StreamingTeleportMagSq', '8192.0')						-- vanilla 4096.0
		-- controlled by game based on RT mode, changing causes instability
		if Var.settings.mode == Var.mode.Raster or Var.settings.mode == Var.mode.RTOnly or Var.settings.mode == Var.mode.RT_PT then
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '64')
		else
			Cyberpunk.SetOption('RayTracing', 'AccelerationStructureBuildNumMax', '128')
		end
		-- controlled by General Shadow Fixes
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateProxyNumMax', '512')			-- PT default is 256	
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'RefitNumMax', '512')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceThreshold', '30.0')
		-- Cyberpunk.SetOption('RayTracing/DynamicInstance', 'UpdateDistanceFactor', '2.0')

		Cyberpunk.SetOption('ResourceLoaderThrottler', 'FloodMinNonLoadingThreads', '-1')		-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'StreamMaxLoadingThreads', '1')			-- vanilla 2
		Cyberpunk.SetOption('ResourceLoaderThrottler', 'TrickleMaxLoadingThreads', '1')			-- vanilla 1

		Cyberpunk.SetOption('Streaming', 'MaxNodesPerFrame', '800')
		Cyberpunk.SetOption('Streaming', 'EditorThrottledMaxNodesPerFrame', '800')

		return
	end
end

return Config
