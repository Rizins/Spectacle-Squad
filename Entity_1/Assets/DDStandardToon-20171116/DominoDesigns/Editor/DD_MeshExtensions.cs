/*
 * The following code was taken from: http://schemingdeveloper.com
 *
 * Visit our game studio website: http://stopthegnomes.com
 *
 * License: You may use this code however you see fit, as long as you include this notice
 *          without any modifications.
 *
 *          You may not publish a paid asset on Unity store if its main function is based on
 *          the following code, but you may publish a paid asset that uses this code.
 *
 *          If you intend to use this in a Unity store asset or a commercial project, it would
 *          be appreciated, but not required, if you let me know with a link to the asset. If I
 *          don't get back to you just go ahead and use it anyway!
 */

// Modified by Domino Marama for generating smooth normals on vertex colors for toon outlines.

using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public static class DD_MeshExtensions
{
    [MenuItem("CONTEXT/Mesh/Generate Toon Data")]
    private static void GenerateToonData(MenuCommand menuCommand) {
        var mesh = menuCommand.context as Mesh;
        Undo.RecordObject(mesh, "Generate Toon Data");
        mesh.GenerateToonData();
    }

    [MenuItem("CONTEXT/Mesh/Generate Toon Data", true)]
    private static bool CanGenerateToonData(MenuCommand menuCommand) {
        var mesh = menuCommand.context as Mesh;
        return (mesh.colors == null || mesh.colors.Length == 0);
    }

    [MenuItem("CONTEXT/Mesh/Save As")]
    public static void SaveMeshNewInstanceItem (MenuCommand menuCommand) {
        var mesh = menuCommand.context as Mesh;
        mesh.Save(true);
    }

    public static void Save (this Mesh mesh, bool makeNewInstance=false, bool optimizeMesh=true) {
        string path = EditorUtility.SaveFilePanel("Save Separate Mesh Asset", "Assets/", mesh.name, "asset");
        if (string.IsNullOrEmpty(path)) return;

        path = FileUtil.GetProjectRelativePath(path);

        Mesh meshToSave = (makeNewInstance) ? UnityEngine.Object.Instantiate(mesh) as Mesh : mesh;

        if (optimizeMesh)
             MeshUtility.Optimize(meshToSave);

        AssetDatabase.CreateAsset(meshToSave, path);
        AssetDatabase.SaveAssets();
    }

    /// <summary>
    ///     Generates initial data for DD Toon shaders in the vertex colors of a mesh.
    ///     RGB hold the outline normals
    ///     A is the outline scale
    /// </summary>
    /// <param name="mesh"></param>

    public static void GenerateToonData(this Mesh mesh) {

        var vertices = mesh.vertices;
        var colors = new Color[vertices.Length];

        // Holds the normal of each triangle in each sub mesh.
        var triNormals = new Vector3[mesh.subMeshCount][];

        var dictionary = new Dictionary<VertexKey, List<VertexEntry>>(vertices.Length);

        for (var subMeshIndex = 0; subMeshIndex < mesh.subMeshCount; ++subMeshIndex) {

            var triangles = mesh.GetTriangles(subMeshIndex);

            triNormals[subMeshIndex] = new Vector3[triangles.Length / 3];

            for (var i = 0; i < triangles.Length; i += 3) {
                int i1 = triangles[i];
                int i2 = triangles[i + 1];
                int i3 = triangles[i + 2];

                // Calculate the normal of the triangle
                Vector3 p1 = vertices[i2] - vertices[i1];
                Vector3 p2 = vertices[i3] - vertices[i1];
                Vector3 normal = Vector3.Cross(p1, p2).normalized;
                int triIndex = i / 3;
                triNormals[subMeshIndex][triIndex] = normal;

                List<VertexEntry> entry;
                VertexKey key;

                if (!dictionary.TryGetValue(key = new VertexKey(vertices[i1]), out entry)) {
                    entry = new List<VertexEntry>(4);
                    dictionary.Add(key, entry);
                }
                entry.Add(new VertexEntry(subMeshIndex, triIndex, i1));

                if (!dictionary.TryGetValue(key = new VertexKey(vertices[i2]), out entry)) {
                    entry = new List<VertexEntry>();
                    dictionary.Add(key, entry);
                }
                entry.Add(new VertexEntry(subMeshIndex, triIndex, i2));

                if (!dictionary.TryGetValue(key = new VertexKey(vertices[i3]), out entry)) {
                    entry = new List<VertexEntry>();
                    dictionary.Add(key, entry);
                }
                entry.Add(new VertexEntry(subMeshIndex, triIndex, i3));
            }
        }

        // Each entry in the dictionary represents a unique vertex position.

        foreach (var vertList in dictionary.Values) {
            for (var i = 0; i < vertList.Count; ++i) {

                var sum = new Vector3();
                var lhsEntry = vertList[i];

                for (var j = 0; j < vertList.Count; ++j) {
                    var rhsEntry = vertList[j];
                    sum += triNormals[rhsEntry.MeshIndex][rhsEntry.TriangleIndex];
                }
                sum = sum.normalized;
                colors[lhsEntry.VertexIndex].r = sum[0];
                colors[lhsEntry.VertexIndex].g = sum[1];
                colors[lhsEntry.VertexIndex].b = sum[2];
                colors[lhsEntry.VertexIndex].a = 1.0f;
            }
        }

        mesh.colors = colors;
    }

    private struct VertexKey
    {
        private readonly long _x;
        private readonly long _y;
        private readonly long _z;

        // Change this if you require a different precision.
        private const int Tolerance = 100000;

        // Magic FNV values. Do not change these.
        private const long FNV32Init = 0x811c9dc5;
        private const long FNV32Prime = 0x01000193;

        public VertexKey(Vector3 position) {
            _x = (long)(Mathf.Round(position.x * Tolerance));
            _y = (long)(Mathf.Round(position.y * Tolerance));
            _z = (long)(Mathf.Round(position.z * Tolerance));
        }

        public override bool Equals(object obj) {
            var key = (VertexKey)obj;
            return _x == key._x && _y == key._y && _z == key._z;
        }

        public override int GetHashCode() {
            long rv = FNV32Init;
            rv ^= _x;
            rv *= FNV32Prime;
            rv ^= _y;
            rv *= FNV32Prime;
            rv ^= _z;
            rv *= FNV32Prime;

            return rv.GetHashCode();
        }
    }

    private struct VertexEntry {
        public int MeshIndex;
        public int TriangleIndex;
        public int VertexIndex;

        public VertexEntry(int meshIndex, int triIndex, int vertIndex) {
            MeshIndex = meshIndex;
            TriangleIndex = triIndex;
            VertexIndex = vertIndex;
        }
    }
}
