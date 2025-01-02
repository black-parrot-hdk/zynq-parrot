from concurrent.futures import ThreadPoolExecutor
import argparse
import random
import subprocess
import sys
import json

cg_sizes = []
nisa_classes = 27
CASCADE_SCRIPT = 'cascade-meta/fuzzer/do_fuzzsingle.py'
class Particle:
  def __init__(self, idx):
    # position: a single distribution over nisa_classes classes
    self.position = [1.0/float(nisa_classes)] * nisa_classes # TODO randomize using zam's

    # velocity: small perturbations to this single distribution
    self.velocity = [0.0]*nisa_classes

    self.idx = idx
    self.fitness = 0.0
    self.pBest = self.position[:]
    self.pBest_fitness = float('-inf')

def normalize_distribution(distr): # TODO consider softmax
  """Normalize a single distribution so sum is 1."""
  s = sum(distr)
  if s == 0:
    return [1.0/len(distr)]*len(distr)
  return [x/s for x in distr]

def evaluate_fitness(p):
  """
  Evaluate fitness: sample a class and compute coverage.
  """
  coverage_map = load_coverage_map(p)
  score = sum(coverage_map) # TODO vectorial score each element corresponding to a cg
  return score

def apply_mutations(position, velocity):
  """
  Update position by adding velocity and normalizing.
  position and velocity are both 1D arrays of length isa_classes
  """
  new_position = [p + v for p, v in zip(position, velocity)]
  new_position = normalize_distribution(new_position)
  return new_position

def compute_mutation_delta(current_pos, target_pos, c):
  """
  Nudge distribution towards target_pos.
  delta[i] = c*(target_pos[i] - current_pos[i])
  """
  return [c*(t - c_val) for c_val, t in zip(current_pos, target_pos)]

def combine_components(inertia_component, cognitive_component, social_component):
  return [i + co + so for i, co, so in zip(inertia_component, cognitive_component, social_component)]

def load_coverage_map(p):
  """
  Load coverage map from file.
  Expecting cg_sizes lines.
  """
  coverage_map = []
  for cg in range(len(cg_sizes)):
    print('covergroup', cg)
    single_group_cov = set() # for uniquifying coverages obtained
    count = 0
    try:
      with open(f'{p.idx}_{cg}.ctrace', 'r') as f:
        for cov in f:
          toggle = int(cov, 16)
          # assert toggle < 2**cg_sizes[num]
          single_group_cov.add(toggle)
          count +=1
    except:
      print('initial program', p.idx)

    coverage_map.append(len(single_group_cov)) # 0 if initial program
    print('\ttotal coverage vectors obtained', count)
    print('\tunique coverage vectors', len(single_group_cov))

  if len(coverage_map) != len(cg_sizes):
    raise ValueError("Coverage file corrupted")

  print('coverage_map', coverage_map)
  return coverage_map

def parse_cp_file(filename):
  return [64]*4 # TODO change according to parse_cp_file

def evaluate_and_update_particle(p):
  # supply new position to cascade and execute a test case
  json_string = json.dumps(p.position)
  print(f'particle {p.idx} launching cascade')
  result = subprocess.run(["python3.9", CASCADE_SCRIPT, json_string], capture_output=False, text=True)

  # Evaluate fitness
  new_fitness = evaluate_fitness(p)
  # Update personal best
  if new_fitness > p.pBest_fitness:
    p.pBest = p.position[:]
    p.pBest_fitness = new_fitness
  return p, new_fitness

def update_particle_velocity_position(p, gBest, w, c1, c2):
  # Inertia component
  inertia_component = [w * v for v in p.velocity]

  # Cognitive component (towards pBest)
  cognitive_component = compute_mutation_delta(p.position, p.pBest, c1*random.random())

  # Social component (towards gBest)
  social_component = compute_mutation_delta(p.position, gBest, c2*random.random())

  # Update velocity
  p.velocity = combine_components(inertia_component, cognitive_component, social_component)

  # Limit velocity magnitude
  for i in range(len(p.velocity)):
    p.velocity[i] = max(min(p.velocity[i], 0.1), -0.1)

  # Update position
  p.position = apply_mutations(p.position, p.velocity)
  return p

def main(args):
  swarm_size = args.swarm_size
  max_iterations = args.iterations
  w = args.inertia_weight
  c1 = args.c1
  c2 = args.c2
  cp_file = args.cp_file

  cg_sizes = parse_cp_file(cp_file)
  # Initialize swarm
  swarm = []
  for idx in range(swarm_size):
    p = Particle(idx)
    p.fitness = evaluate_fitness(p)
    p.pBest = p.position[:]
    p.pBest_fitness = p.fitness
    swarm.append(p)

  # Find global best
  best_particle = max(swarm, key=lambda x: x.fitness)
  gBest = best_particle.position[:]
  gBest_fitness = best_particle.fitness

  # Create a thread pool for parallel execution
  with ThreadPoolExecutor(max_workers=4) as executor:
    for iteration in range(max_iterations):
      # Evaluate fitness and update pBests in parallel
      futures = [executor.submit(evaluate_and_update_particle, p) for p in swarm]
      results = [f.result() for f in futures]

      # Update swarm with new fitness and pBests
      for i, (p, new_fitness) in enumerate(results):
        swarm[i] = p
        # Update global best after collecting all results
        if new_fitness > gBest_fitness:
          gBest = p.position[:]
          gBest_fitness = new_fitness

      # Update velocities and positions in parallel
      futures = [executor.submit(update_particle_velocity_position, p, gBest, w, c1, c2) for p in swarm]
      swarm = [f.result() for f in futures]

      if iteration % 10 == 0:
        print(f"Iteration {iteration}: Current gBest fitness = {gBest_fitness}")

  print("Final gBest fitness:", gBest_fitness)
  print("Final gBest distribution:", gBest)


if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="PSO-based Fuzzing with a Single-Dimension Probability Distribution.")
  parser.add_argument("--swarm_size", type=int, default=1, help="Number of particles in the swarm")
  parser.add_argument("--iterations", type=int, default=2, help="Number of iterations to run PSO")
  parser.add_argument("--inertia_weight", type=float, default=0.5, help="Inertia weight (w) in PSO")
  parser.add_argument("--c1", type=float, default=2.0, help="Cognitive parameter (c1)")
  parser.add_argument("--c2", type=float, default=2.0, help="Social parameter (c2)")
  parser.add_argument("--cp_file", type=str, default='surelog.run/cp.csv', required=False, help="File containing covergroup descriptions")
  args = parser.parse_args()
  main(args)
