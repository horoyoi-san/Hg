using Campofinale.Database;
using Campofinale.Protocol;
using System.Collections.Generic;
using System.Linq;

namespace Campofinale.Game.MapMarks
{
	/// <summary>
	/// Map mark manager for a player.
	/// Manages map marks and track points, handles persistence, and converts to protocol messages.
	/// </summary>
	public class MapMarkManager
	{
		public Player owner;
		// Static map marks: only store discovered indices, actual data loaded from config table
		public List<int> discoveredStaticMarkIndices = new();
		public List<SceneDynamicMapMark> sceneDynamicMapMarkList = new();
		public SceneTrackPoint trackPoint = new();

		/// <summary>
		/// Initialize map mark manager for a player.
		/// </summary>
		/// <param name="o">Player owner</param>
		public MapMarkManager(Player o)
		{
			owner = o;
		}

		/// <summary>
		/// Creates the initial map mark state for a new player.
		/// Returns an empty ScSceneMapMarkSync as the initial state.
		/// </summary>
		/// <returns>ScSceneMapMarkSync with empty initial state</returns>
		public static ScSceneMapMarkSync CreateInitialState()
		{
			return new ScSceneMapMarkSync();
		}

		/// <summary>
		/// Convert map mark state to ScSceneMapMarkSync protocol message.
		/// Static marks are converted from indices to SceneStaticMapMark objects.
		/// </summary>
		/// <returns>ScSceneMapMarkSync protocol message</returns>
		public ScSceneMapMarkSync ToProto()
		{
			ScSceneMapMarkSync sync = new ScSceneMapMarkSync();
			// Convert discovered indices to SceneStaticMapMark objects
			foreach (int index in discoveredStaticMarkIndices)
			{
				sync.SceneStaticMapMarkList.Add(new SceneStaticMapMark { Index = index });
			}
			if (sceneDynamicMapMarkList != null)
			{
				sync.SceneDynamicMapMarkList.AddRange(sceneDynamicMapMarkList);
			}
			sync.TrackPoint = trackPoint ?? new SceneTrackPoint();
			return sync;
		}

		/// <summary>
		/// Save map mark state to database.
		/// </summary>
		public void Save()
		{
			DatabaseManager.db.UpsertMapMarkData(new MapMarkData()
			{
				roleId = owner.roleId,
				discoveredStaticMarkIndices = discoveredStaticMarkIndices,
				sceneDynamicMapMarkList = sceneDynamicMapMarkList,
				trackPoint = trackPoint ?? new SceneTrackPoint()
			});
		}

		/// <summary>
		/// Load map mark state from database.
		/// If no data found (e.g., old accounts created before map mark system), automatically creates and saves initial state to database.
		/// This ensures backward compatibility with existing accounts and ensures database always has a record.
		/// </summary>
		public void Load()
		{
			MapMarkData? data = DatabaseManager.db.LoadMapMarkData(owner.roleId);
			if (data != null)
			{
				// Load discovered static mark indices
				discoveredStaticMarkIndices.Clear();
				if (data.discoveredStaticMarkIndices != null)
				{
					discoveredStaticMarkIndices.AddRange(data.discoveredStaticMarkIndices);
				}
				sceneDynamicMapMarkList.Clear();
				if (data.sceneDynamicMapMarkList != null)
				{
					sceneDynamicMapMarkList.AddRange(data.sceneDynamicMapMarkList);
				}
				trackPoint = data.trackPoint ?? new SceneTrackPoint();
			}
			else
			{
				// If no data found, initialize from clean state (empty map marks)
				// This handles old accounts that don't have mapMarkData collection entry
				InitializeFromCleanState(CreateInitialState());
				// Save the initial state to database so it exists for future loads
				Save();
			}
		}

		/// <summary>
		/// Initialize map mark manager from clean state (for new players).
		/// </summary>
		/// <param name="cleanState">Clean initial map mark state</param>
		public void InitializeFromCleanState(ScSceneMapMarkSync cleanState)
		{
			discoveredStaticMarkIndices.Clear();
			if (cleanState.SceneStaticMapMarkList != null)
			{
				foreach (var mark in cleanState.SceneStaticMapMarkList)
				{
					if (!discoveredStaticMarkIndices.Contains(mark.Index))
					{
						discoveredStaticMarkIndices.Add(mark.Index);
					}
				}
			}
			sceneDynamicMapMarkList.Clear();
			if (cleanState.SceneDynamicMapMarkList != null)
			{
				sceneDynamicMapMarkList.AddRange(cleanState.SceneDynamicMapMarkList);
			}
			trackPoint = cleanState.TrackPoint ?? new SceneTrackPoint();
		}

		/// <summary>
		/// Add a static map mark index (player selected to show this mark).
		/// Static mark data is loaded from LevelMapMark config table, we only store the index.
		/// </summary>
		/// <param name="index">Static map mark index (serverMarkIndex from config)</param>
		public void AddStaticMapMarkIndex(int index)
		{
			if (!discoveredStaticMarkIndices.Contains(index))
			{
				discoveredStaticMarkIndices.Add(index);
			}
		}

		/// <summary>
		/// Remove a static map mark index (player deselected this mark).
		/// </summary>
		/// <param name="index">Static map mark index</param>
		public void RemoveStaticMapMarkIndex(int index)
		{
			discoveredStaticMarkIndices.Remove(index);
		}

		/// <summary>
		/// Set track point.
		/// </summary>
		/// <param name="trackPoint">Track point to set</param>
		public void SetTrackPoint(SceneTrackPoint trackPoint)
		{
			this.trackPoint = trackPoint ?? new SceneTrackPoint();
		}

		/// <summary>
		/// Add a dynamic map mark.
		/// </summary>
		/// <param name="mark">Dynamic map mark to add</param>
		public void AddDynamicMapMark(SceneDynamicMapMark mark)
		{
			if (mark != null)
			{
				// Remove existing mark with same ID and scene if exists (replace)
				sceneDynamicMapMarkList.RemoveAll(m => m.Id == mark.Id && m.SceneNumId == mark.SceneNumId);
				sceneDynamicMapMarkList.Add(mark);
			}
		}

		/// <summary>
		/// Remove dynamic map marks by IDs for a specific scene.
		/// </summary>
		/// <param name="sceneNumId">Scene number ID</param>
		/// <param name="ids">List of mark IDs to remove</param>
		public void RemoveDynamicMapMarks(int sceneNumId, List<uint> ids)
		{
			sceneDynamicMapMarkList.RemoveAll(m => m.SceneNumId == sceneNumId && ids.Contains(m.Id));
		}

		/// <summary>
		/// Update a dynamic map mark.
		/// </summary>
		/// <param name="sceneNumId">Scene number ID</param>
		/// <param name="id">Mark ID</param>
		/// <param name="note">New note text</param>
		/// <param name="typ">New type</param>
		public void UpdateDynamicMapMark(int sceneNumId, uint id, string note, uint typ)
		{
			var mark = sceneDynamicMapMarkList.FirstOrDefault(m => m.SceneNumId == sceneNumId && m.Id == id);
			if (mark != null)
			{
				mark.Note = note;
				mark.Typ = typ;
			}
		}
	}
}

