# OpenRA.Game

## 渲染流程概览
渲染过程调用的都是Game.Render的方法，它本质上运行的是底层为sdl2，使用封装好的OpenGL方法

* Game.InitializeAndRun
    - Initialize
        - new Platform
            - new Sdl2PlatformWindow
        - new Renderer
            - Context = Window.Context
        - InitializeMod: 清空一切UI, worldRenderer, ModData
            - new LocalPlayerProfile
            - ModData.InitializeLoaders(ModData.DefaultFileSystem)
			- Renderer.InitializeFonts(ModData): 新建SpriteFont，之后通过RgbaSpriteRenderer渲染
            - Renderer.InitializeDepthBuffer(grid)
            - JoinLocal(): 新建OrderManager
            - ModData.LoadScreen.StartGame(args);
    - Run
        - Loop: 游戏跑在一个大循环中，通过now和nextUpdate的RunTime时间戳比较来更新和渲染
            - LogicTick()
                - InnerLogicTick(OrderManager)
                    - Sound.Tick()
                    - world.Tick()
                    - PerfHistory.Tick()
            - RenderTick(): 用了using作检查
                - render_prepare: 准备渲染，准备可渲染的组件
                - render_world：渲染主要方法
                    - worldRenderer.Draw()
                        - Game.Renderer.EnableScissor(bounds): 裁剪边界
                        - Game.Renderer.Context.EnableDepthBuffer()：启用深度缓冲，后渲染的可以被之前的遮挡
                        - terrainRenderer?.RenderTerrain(this, Viewport)：渲染地形
                            - foreach (var r in wr.World.WorldActor.TraitsImplementing<IRenderOverlay>()) r.Render(wr);：将实现了IRenderOverlay的Actor调用renderer方法
                                例如不同Mod中的ResourceRender,SmudgeLayer,BuildableTerrainLayer
                        - preparedRenderables[i].Render(this)：渲染可渲染的组件
                        - Game.Renderer.ClearDepthBuffer()：清除深度缓冲，以下重新计算遮挡
                        - World.ActorsWithTrait<IRenderShroud>().Trait.RenderShroud(this): 待补充
                        - Game.Renderer.Context.DisableDepthBuffer()：停用深度缓冲
                        - Game.Renderer.DisableScissor()
                            - WorldSpriteRenderer.DrawVertexBuffer方法将vertexBuffer中的数据进行渲染
                                调用的是Sdl2PlatformWindow的Sdl2GraphicsContext进行渲染vertex
                                    其中直接调用OpenGL的底层方法

                - render_widgets：渲染UI主要方法，包括鼠标样式
                    - Ui.Draw()
                    - Cursor.Render(Renderer)
                - render_flip：停止渲染



## Map加载概览(待补充)

* StartGame
    - ModData.PrepareMap(mapUID)：加载声音，鼠标
        - new Map()
            - 建立不同的CellLayer: Tiles, Resources, Height, Ramp
            - 将UpdateProjection添加到CellLayer的CellEntryChanged
        - PostInit()
            - 建立不同的CellLayer: CustomTerrain
            - Ruleset.Load: 加载modData中actor, weapon, sound, music, terrainInfo,sequence modelsequence
            - 获取Rules中Tiles和Ramp信息

            - InitializeCellProjection()
                - 建立不同的CellLayer: cellProjection, inverseCellProjection, projectedHeight
                - UpdateProjection()

* TerrainSpriteLayer
    - 获得World中的Map对象，每次绘画时，获得Map对象中的cell来更新vertices
