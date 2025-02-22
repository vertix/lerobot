import torch

from lerobot.common.datasets.lerobot_dataset import LeRobotDataset


def compose_rotvecs(rotvec1: torch.Tensor, rotvec2: torch.Tensor) -> torch.Tensor:
    """
    Compose two rotation vectors (applies rotvec2 after rotvec1).
    Uses the Baker-Campbell-Hausdorff formula for small angles.

    Args:
        rotvec1: First rotation vector of shape (..., 3)
        rotvec2: Second rotation vector of shape (..., 3)

    Returns:
        Composed rotation vector of shape (..., 3)
    """
    theta1 = torch.norm(rotvec1, dim=-1, keepdim=True)
    theta2 = torch.norm(rotvec2, dim=-1, keepdim=True)

    # Normalize rotation vectors (handle zero case)
    w1 = rotvec1 / (theta1 + 1e-8)
    w2 = rotvec2 / (theta2 + 1e-8)

    # Cross product of normalized vectors
    w1_cross_w2 = torch.cross(w1, w2, dim=-1)

    # Dot product of normalized vectors
    w1_dot_w2 = torch.sum(w1 * w2, dim=-1, keepdim=True)

    # Compute the composed rotation using BCH formula
    c1 = torch.cos(theta1/2)
    c2 = torch.cos(theta2/2)
    s1 = torch.sin(theta1/2)
    s2 = torch.sin(theta2/2)

    A = c1*c2 - s1*s2*w1_dot_w2
    B = c1*s2*w2 + c2*s1*w1 + s1*s2*w1_cross_w2

    theta = 2 * torch.atan2(torch.norm(B, dim=-1, keepdim=True), A)
    w = B / (torch.norm(B, dim=-1, keepdim=True) + 1e-8)

    result = theta * w

    # Handle special cases
    small_angle = (theta1 < 1e-4) & (theta2 < 1e-4)
    if small_angle.any():
        result[small_angle] = rotvec1[small_angle] + rotvec2[small_angle]

    return result


def invert_rotvec(rotvec: torch.Tensor) -> torch.Tensor:
    """
    Invert a rotation vector.

    Args:
        rotvec: Rotation vector of shape (..., 3)

    Returns:
        Inverted rotation vector of shape (..., 3)
    """
    return -rotvec


def apply_rotvec_to_point(rotvec: torch.Tensor, point: torch.Tensor) -> torch.Tensor:
    """
    Apply rotation vector to a point.

    Args:
        rotvec: Rotation vector of shape (..., 3)
        point: Point to rotate of shape (..., 3)

    Returns:
        Rotated point of shape (..., 3)
    """
    theta = torch.norm(rotvec, dim=-1, keepdim=True)
    w = rotvec / (theta + 1e-8)

    cos_theta = torch.cos(theta)
    sin_theta = torch.sin(theta)

    # Rodrigues' formula directly on point
    return (cos_theta * point +
            sin_theta * torch.cross(w, point, dim=-1) +
            (1 - cos_theta) * (torch.sum(w * point, dim=-1, keepdim=True) * w))


@torch.compile
def delta_position_to_relative(action: torch.Tensor) -> torch.Tensor:
    """
    Convert a sequence of delta positions to positions relative to the first position.

    Given a sequence of delta transforms T_i where each transform represents the change
    from position P_(i-1) to P_i, converts them to transforms relative to the first position P_0.

    Input sequence: [T_1, T_2, T_3, ...] where P_i = P_(i-1) * T_i
    Output sequence: [T'_1, T'_2, T'_3, ...] where P_i = P_0 * T'_i

    Args:
        action: A tensor of shape (N, 6) containing the delta positions,
               where each row is [rx, ry, rz, tx, ty, tz]
               (rotation vector followed by translation).

    Returns:
        A tensor of shape (N, 6) containing the relative positions.
    """
    rotvecs = action[..., :3]
    positions = action[..., 3:6]

    # Initialize output tensors
    rel_rotvecs = torch.zeros_like(rotvecs)
    rel_positions = torch.zeros_like(positions)

    # First transform stays the same
    rel_rotvecs[0] = rotvecs[0]
    rel_positions[0] = positions[0]

    # Compute absolute rotations and positions
    curr_rotvec = rotvecs[0]
    curr_pos = positions[0]

    for i in range(1, len(rotvecs)):
        # Update rotation
        curr_rotvec = compose_rotvecs(curr_rotvec, rotvecs[i])

        # Update position: first rotate new delta position by current rotation, then add
        rotated_delta = apply_rotvec_to_point(curr_rotvec, positions[i])
        curr_pos = curr_pos + rotated_delta

        # Convert to relative to first position
        rel_rotvecs[i] = curr_rotvec
        rel_positions[i] = curr_pos

    # Combine rotations and translations
    return torch.cat([rel_rotvecs, rel_positions, action[..., 6:]], dim=-1)


class RelativePositionDataset(torch.utils.data.Dataset):
    def __init__(self, base_dataset: LeRobotDataset):
        self.base_dataset = base_dataset

    def __len__(self):
        return len(self.base_dataset)

    def __getitem__(self, idx):
        item = self.base_dataset[idx]

        item['action'] = delta_position_to_relative(item['action'])
        return item

    @property
    def fps(self) -> int:
        """Frames per second used during data collection."""
        return self.base_dataset.fps

    @property
    def video(self) -> bool:
        """Returns True if this dataset loads video frames from mp4 files.
        Returns False if it only loads images from png files.
        """
        return self.base_dataset.video

    @property
    def features(self):
        return self.base_dataset.features

    @property
    def camera_keys(self) -> list[str]:
        """Keys to access image and video stream from cameras."""
        return self.base_dataset.camera_keys

    @property
    def video_frame_keys(self) -> list[str]:
        """Keys to access video frames that requires to be decoded into images.

        Note: It is empty if the dataset contains images only,
        or equal to `self.cameras` if the dataset contains videos only,
        or can even be a subset of `self.cameras` in a case of a mixed image/video dataset.
        """
        return self.base_dataset.video_frame_keys

    @property
    def num_samples(self) -> int:
        """Number of samples/frames."""
        return self.base_dataset.num_samples

    @property
    def num_episodes(self) -> int:
        """Number of episodes."""
        return self.base_dataset.num_episodes

    @property
    def tolerance_s(self) -> float:
        """Tolerance in seconds used to discard loaded frames when their timestamps
        are not close enough from the requested frames. It is only used when `delta_timestamps`
        is provided or when loading video frames from mp4 files.
        """
        return self.base_dataset.tolerance_s
