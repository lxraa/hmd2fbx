/**
 * HMD/HWD to FBX Converter
 * Converts Heaps Model Data files back to FBX format
 */
class HMD2FBX {
    
    static function main() {
        var args = Sys.args();
        if(args.length < 2) {
            Sys.println("");
            Sys.println("HMD2FBX - Heaps Model Data to FBX Converter");
            Sys.println("=".repeat(50));
            Sys.println("");
            Sys.println("Usage: HMD2FBX <input.hmd|hwd> <output.fbx>");
            Sys.println("");
            Sys.println("Examples:");
            Sys.println("  HMD2FBX model.hmd model.fbx");
            Sys.println("  HMD2FBX game_model.hwd exported.fbx");
            Sys.println("");
            return;
        }
        
        var inputFile = args[0];
        var outputFile = args[1];
        
        try {
            Sys.println("");
            Sys.println("=".repeat(60));
            Sys.println("HMD2FBX Converter");
            Sys.println("=".repeat(60));
            Sys.println("");
            
            // Step 1: Read HMD file
            Sys.println("[1/4] Reading HMD file...");
            Sys.println("      Input:  " + inputFile);
            
            var res = new SimpleResource(inputFile);
            var bytes = sys.io.File.getBytes(inputFile);
            var reader = new hxd.fmt.hmd.Reader(new haxe.io.BytesInput(bytes));
            var hmd = reader.read();
            
            Sys.println("      ✓ HMD Version: " + hmd.version);
            Sys.println("      ✓ Models: " + hmd.models.length);
            Sys.println("      ✓ Geometries: " + hmd.geometries.length);
            Sys.println("      ✓ Materials: " + hmd.materials.length);
            Sys.println("");
            
            // Step 2: Load geometry data
            Sys.println("[2/4] Loading geometry data...");
            var lib = new hxd.fmt.hmd.Library(res, hmd);
            Sys.println("      ✓ Library initialized");
            Sys.println("");
            
            // Step 3: Build scene objects
            Sys.println("[3/4] Building scene objects...");
            var objects = buildSceneObjects(hmd, lib);
            Sys.println("      ✓ Built " + objects.length + " scene object(s)");
            Sys.println("");
            
            // Step 4: Export to FBX
            Sys.println("[4/4] Exporting to FBX...");
            Sys.println("      Output: " + outputFile);
            
            var out = new haxe.io.BytesOutput();
            var writer = new hxd.fmt.fbx.Writer(out);
            
            var params:hxd.fmt.fbx.Writer.ExportParams = {
                forward: "0",
                forwardSign: "-1", 
                up: "2",
                upSign: "1"
            };
            
            writer.write(objects, params);
            sys.io.File.saveBytes(outputFile, out.getBytes());
            
            var fileSize = sys.FileSystem.stat(outputFile).size;
            var sizeKB = Math.round(fileSize / 1024.0 * 10) / 10;
            Sys.println("      ✓ File saved (" + sizeKB + " KB)");
            Sys.println("");
            
            Sys.println("=".repeat(60));
            Sys.println("✓ Conversion completed successfully!");
            Sys.println("=".repeat(60));
            Sys.println("");
            
        } catch(e:Dynamic) {
            Sys.println("");
            Sys.println("=".repeat(60));
            Sys.println("✗ ERROR");
            Sys.println("=".repeat(60));
            Sys.println("");
            Sys.println("Error: " + e);
            Sys.println("");
            Sys.println("Stack trace:");
            Sys.println(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            Sys.println("");
            Sys.exit(1);
        }
    }
    
    // Create a Polygon primitive from HMD geometry data
    static function createPolygonFromGeometry(geom:hxd.fmt.hmd.Data.Geometry, lib:hxd.fmt.hmd.Library):h3d.prim.Polygon {
        // Determine the format we need
        var format = geom.vertexFormat;
        
        // Get raw buffer data from library
        var buffers = lib.getBuffers(geom, format);
        
        var stride = format.stride;
        var vertexCount = geom.vertexCount;
        
        // Extract vertex positions
        var points = new Array<h3d.col.Point>();
        var normals:Array<h3d.col.Point> = null;
        var uvs:Array<h3d.prim.UV> = null;
        
        var hasNormal = format.hasInput("normal");
        var hasUV = format.hasInput("uv");
        
        if(hasNormal) normals = new Array<h3d.col.Point>();
        if(hasUV) uvs = new Array<h3d.prim.UV>();
        
        // Calculate offsets for each attribute
        // calculateInputOffset returns byte offset, we need float offset (divide by 4)
        var posOffset = 0;
        var normalOffset = hasNormal ? Std.int(format.calculateInputOffset("normal") / 4) : 0;
        var uvOffset = hasUV ? Std.int(format.calculateInputOffset("uv") / 4) : 0;
        
        // Extract vertex data
        for(i in 0...vertexCount) {
            var baseIdx = i * stride;
            
            // Position (always present)
            var x = buffers.vertexes[baseIdx + posOffset];
            var y = buffers.vertexes[baseIdx + posOffset + 1];
            var z = buffers.vertexes[baseIdx + posOffset + 2];
            points.push(new h3d.col.Point(x, y, z));
            
            // Normal
            if(hasNormal) {
                var nx = buffers.vertexes[baseIdx + normalOffset];
                var ny = buffers.vertexes[baseIdx + normalOffset + 1];
                var nz = buffers.vertexes[baseIdx + normalOffset + 2];
                normals.push(new h3d.col.Point(nx, ny, nz));
            }
            
            // UV
            if(hasUV) {
                var u = buffers.vertexes[baseIdx + uvOffset];
                var v = buffers.vertexes[baseIdx + uvOffset + 1];
                uvs.push(new h3d.prim.UV(u, v));
            }
        }
        
        // Extract indices
        var idx = new hxd.IndexBuffer();
        for(i in 0...buffers.indexes.length) {
            idx.push(buffers.indexes[i]);
        }
        
        // Create polygon
        var poly = new h3d.prim.Polygon(points, idx);
        poly.normals = normals;
        poly.uvs = uvs;
        
        return poly;
    }
    
    static function buildSceneObjects(hmd:hxd.fmt.hmd.Data, lib:hxd.fmt.hmd.Library):Array<h3d.scene.Object> {
        var objects = new Array<h3d.scene.Object>();
        var modelObjects = new Map<Int, h3d.scene.Object>();
        
        // Create objects for each model
        for(i in 0...hmd.models.length) {
            var model = hmd.models[i];
            var obj:h3d.scene.Object = null;
            
            if(model.geometry >= 0) {
                // This is a mesh - create polygon from geometry data
                try {
                    var geom = hmd.geometries[model.geometry];
                    var poly = createPolygonFromGeometry(geom, lib);
                    
                    // Create material
                    var mat = h3d.mat.Material.create();
                    if(model.materials.length > 0) {
                        var matData = hmd.materials[model.materials[0]];
                        mat.name = matData.name;
                        mat.blendMode = matData.blendMode;
                        
                        // Log texture references
                        if(matData.diffuseTexture != null) {
                            Sys.println('  Material ${mat.name}: Diffuse = ${matData.diffuseTexture}');
                        }
                        if(matData.specularTexture != null) {
                            Sys.println('  Material ${mat.name}: Specular = ${matData.specularTexture}');
                        }
                        if(matData.normalMap != null) {
                            Sys.println('  Material ${mat.name}: Normal = ${matData.normalMap}');
                        }
                    }
                    
                    var mesh = new h3d.scene.Mesh(poly, mat);
                    mesh.name = model.name != null ? model.name : 'Model_${i}';
                    obj = mesh;
                    
                    Sys.println('  Created mesh: ${mesh.name} (${geom.vertexCount} vertices, ${Std.int(geom.indexCount/3)} triangles)');
                    
                } catch(e:Dynamic) {
                    Sys.println('  Error: Could not create mesh for model $i (${model.name}): $e');
                    Sys.println('  Stack: ${haxe.CallStack.toString(haxe.CallStack.exceptionStack())}');
                    obj = new h3d.scene.Object();
                    obj.name = model.name != null ? model.name : 'Model_${i}';
                }
            } else {
                // This is just a transform node
                obj = new h3d.scene.Object();
                obj.name = model.name != null ? model.name : 'Model_${i}';
                Sys.println('  Created transform node: ${obj.name}');
            }
            
            // Set transform
            if(model.position != null) {
                obj.defaultTransform = model.position.toMatrix();
            }
            
            modelObjects.set(i, obj);
        }
        
        // Build hierarchy
        for(i in 0...hmd.models.length) {
            var model = hmd.models[i];
            var obj = modelObjects.get(i);
            
            if(model.parent >= 0 && modelObjects.exists(model.parent)) {
                var parent = modelObjects.get(model.parent);
                parent.addChild(obj);
            } else {
                // Root object
                objects.push(obj);
            }
        }
        
        return objects;
    }
}

// Simple resource wrapper for file-based HMD loading
class SimpleResource extends hxd.res.Resource {
    var filePath:String;
    var fileEntry:SimpleFileEntry;
    
    public function new(path:String) {
        this.filePath = path;
        this.fileEntry = new SimpleFileEntry(path);
        super(this.fileEntry);
    }
}

class SimpleFileEntry extends hxd.fs.FileEntry {
    var filePath:String;
    var cachedBytes:haxe.io.Bytes;
    var fileName:String;
    
    public function new(path:String) {
        this.filePath = path;
        // Extract filename from path
        var parts = path.split("/");
        if(parts.length == 0) parts = path.split("\\");
        this.fileName = parts[parts.length - 1];
        // Set the name field directly
        @:privateAccess this.name = this.fileName;
    }
    
    override function get_path():String {
        return filePath;
    }
    
    override function get_size():Int {
        if(cachedBytes == null) {
            cachedBytes = sys.io.File.getBytes(filePath);
        }
        return cachedBytes.length;
    }
    
    override function getBytes():haxe.io.Bytes {
        if(cachedBytes == null) {
            cachedBytes = sys.io.File.getBytes(filePath);
        }
        return cachedBytes;
    }
    
    override function readFull(out:haxe.io.Bytes, pos:Int, len:Int):Void {
        if(cachedBytes == null) {
            cachedBytes = sys.io.File.getBytes(filePath);
        }
        out.blit(0, cachedBytes, pos, len);
    }
    
    override function fetchBytes(pos:Int, len:Int):haxe.io.Bytes {
        if(cachedBytes == null) {
            cachedBytes = sys.io.File.getBytes(filePath);
        }
        return cachedBytes.sub(pos, len);
    }
}
