root_dir=$HOME/Exp/OpenUAV

cd $root_dir

python $root_dir/airsim_plugin/AirVLNSimulatorServerTool.py --gpus 1 --port 25000 --root_path $root_dir/envs/