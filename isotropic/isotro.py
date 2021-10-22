# http://corysimon.github.io/articles/uniformdistn-on-sphere/
# https://stackoverflow.com/questions/5408276/sampling-uniformly-distributed-random-points-inside-a-spherical-volume

# https://stackoverflow.com/a/33977530

import numpy as np

def sample(npoints, ndim=3, seed=None):
    np.random.seed(seed=seed)
    vec = np.random.randn(ndim, npoints)
    vec /= np.linalg.norm(vec, axis=0)
    return vec

# # this requires numpy.__version__ >= 1.17.0
# def sample(npoints, ndim=3, seed=None):
#     rng = np.random.default_rng(seed=seed)
#     vec = rng.standard_normal(size=(ndim, npoints))
#     vec /= np.linalg.norm(vec, axis=0)
#     return vec

if __name__ == '__main__':

    from matplotlib import pyplot as plt

    #--------------------------------------------------------------------------

    # from mpl_toolkits.mplot3d import axes3d

    # phi = np.linspace(0, np.pi, 20)
    # theta = np.linspace(0, 2 * np.pi, 40)
    # x = np.outer(np.sin(theta), np.cos(phi))
    # y = np.outer(np.sin(theta), np.sin(phi))
    # z = np.outer(np.cos(theta), np.ones_like(phi))

    # xi, yi, zi = sample(100)

    # fig, ax = plt.subplots(1, 1, subplot_kw={'projection':'3d', 'aspect':'equal'})
    # #fig, ax = plt.subplots(1, 1, subplot_kw={'projection':'3d'})
    # ax.plot_wireframe(x, y, z, color='k', rstride=1, cstride=1)
    # ax.scatter(xi, yi, zi, s=100, c='r', zorder=10)

    # plt.show()

    # plt.cla()
    # plt.clf()
    # plt.close()

    #--------------------------------------------------------------------------

    n = 1000000

    x, y, z = sample(n, seed=3)

    theta = np.arctan(np.sqrt(x*x + y*y)/z)
    phi = np.arctan(y/x)

    theta[theta < 0] += np.pi
    phi[phi < 0] += np.pi

    # print(theta)
    # print(phi)

    """

    def dot_products(x, y):
        return np.einsum('ij,ji->i', x, y.T)

    v = np.vstack([x, y, z]).T
    dot = np.einsum('ij,ji->i', v, v.T)

    # print(np.vstack([theta, phi]))
    print(x)
    print(y)
    print(z)
    print(v)
    print(v.T)
    print(dot)
    print(v[:, :-1])
    print(np.einsum('ij,ji->i', v[:, :-1], v[:, :-1].T))
    print(dot_products(v[:, :-1], v[:, :-1]))

    xy = np.zeros((2*n, 3))
    xy[:, 0] = 1

    print(xy)

    xy[::2] = v

    print(xy)
    xy = xy[:, :2]
    print(xy)

    xy = np.reshape(xy, (n, 2, 2))
    det_xy = np.linalg.det(xy)
    dot_xy = dot_products(v[:, :2], v[:, :2])
    angle_xy = np.arctan2(det_xy, dot_xy) * 180. / np.pi

    print(angle_xy)

    # det [[a, b], [c, d]] is ad - bc

    # fig = plt.figure(figsize=(7, 5))
    # ax = fig.add_subplot(1, 1, 1)
    # 
    # ax.hist(angle_xy)
    # plt.show()
    # 
    # from sys import exit
    # exit()

    # https://stackoverflow.com/a/16544330

    # dot = x1*x2 + y1*y2        # dot product between [x1, y1] and [x2, y2]
    # det = x1*y2 - y1*x2        # determinant
    # angle = arctan2(det, dot)  # arctan2(y, x) or arctan2(sin, cos)

    """

    fig = plt.figure(figsize=(7, 5))
    ax = fig.add_subplot(1, 1, 1)

    # x_bin_lower = -1.58
    # x_bin_upper = 1.58
    x_bin_lower = 0.00
    x_bin_upper = 3.16
    x_bin_width = 0.02

    # y_bin_lower = -1.58
    # y_bin_upper = 1.58
    y_bin_lower = 0.00
    y_bin_upper = 3.16
    y_bin_width = 0.02

    x_data, y_data = phi, theta

    x_bins = np.arange(x_bin_lower, x_bin_upper+x_bin_width, x_bin_width)
    y_bins = np.arange(y_bin_lower, y_bin_upper+y_bin_width, y_bin_width)

    counts, x_edges, y_edges = np.histogram2d(x_data, y_data, bins=(x_bins, y_bins))

    x, y = np.meshgrid(x_bins, y_bins)
    # p = ax.pcolormesh(x, y, counts.T, shading='auto')  # without mask
    p = ax.pcolormesh(x, y, np.ma.masked_where(counts == 0, counts).T, shading='auto')  # with mask

    p.set_rasterized(True)

    # ax.scatter(phi, theta)
    # ax.hist2d(phi, theta, bins=(100, 100))

    plt.xticks(fontsize=12)
    plt.yticks(fontsize=12)

    ax.set_xlabel(r'$\phi$ [rad]', horizontalalignment='right', x=1.0, fontsize=14)
    ax.set_ylabel(r'$\theta$ [rad]', horizontalalignment='right', y=1.0, fontsize=14)

    ax.set_aspect('equal')

    cbar = fig.colorbar(p)
    cbar.set_label('entries per {} rad per {} rad'.format(x_bin_width, y_bin_width), rotation=90, size=14)
    cbar.ax.tick_params(labelsize=14)

    plt.tight_layout()

    plt.show()

    #--------------------------------------------------------------------------

