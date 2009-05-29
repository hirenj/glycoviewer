class SequenceSetsController < StructureSummaryController
  layout 'standard'
  
  def sequence_sets
    session[:sequence_sets] ||= {}
    session[:sequence_sets]
  end
  
  def set_id
    params[:setid] ? params[:setid].to_sym : :default
  end
  
  def current_sequence_set
    if sequence_sets[set_id] == nil
      sequence_sets[set_id] = []
    end
    sequence_sets[set_id]
  end
  
  def current_sugar_set
    seq_counter = 0
    last_sug = nil
    last_seq = nil
    
    current_sequence_set.select { |seq|
      if seq =~ /\?\)/ || seq =~ /u[1,2]/ || seq =~ /\?[1,2]/
        false
      else
        true
      end
    }.sort.collect { |seq|
      seq_counter += 1
      my_seq = seq.gsub(/\+.*/,'').gsub(/\(\?/,'(u')
      my_seq.gsub!(/\(-/,'(u1-')
      my_sug = nil
      begin
        if last_seq != nil && my_seq == last_seq
          my_sug = last_sug
        else
          my_sug = SugarHelper.CreateMultiSugar(my_seq,:ic).get_unique_sugar
        end        
        logger.info(seq)
        my_sug.residue_composition.each { |res|
          if my_sug != last_sug
            res.extend(HitCounter)
          end
          
          res.initialise_counter(:id)
          res.get_counter(:id)
          res.increment_counter(seq_counter,:id)
        }

        next unless last_seq != my_seq

        last_sug = my_sug
        last_seq = my_seq

      rescue Exception => e
        logger.info(e)
        last_seq = nil
        last_sug = nil
      end
      my_sug
    }.compact
  end

  def markup_sugarset(sugarset)
    sugarset.each { |sugar|
      markup_chains(sugar)
      markup_branch_points(sugar)
    }
  end

  
  def summary
    self.statistic_collectors = [branch_collector,fuc_collector,neuac_collector]
    sugarset = execute_summary_for_sugars(current_sugar_set)
    logger.info(current_sugar_set.size)
    markup_sugarset(sugarset)
    
    @sugars = sugarset    
    render :template => 'glycodbs/coverage.html.erb', :content_type => Mime::XHTML    
  end
  
  def add
    current_sequence_set << params[:id] if params[:id]
    current_sequence_set.concat(params[:seqs].split("\n")) if (params[:seqs] || '').size > 0
    @sequences = current_sequence_set
    respond_to do |format|
        format.txt { render :text => @sequences.join("\n") }
        format.xhtml { render }
    end
  end
  
  def clear
    current_sequence_set.clear
    @sequences = []
    render :action => 'add'
  end
  
  def delete
    current_sequence_set.delete(params[:id])
    respond_to do |format|
        format.txt { render :text => current_sequence_set.join("\n") }
        format.xhtml { render }
    end
  end
  
  def list
    @sequences = current_sequence_set
    respond_to do |format|
        format.txt { render :text => @sequences.join("\n") }
        format.xhtml { render :action => 'list' }
    end
  end
  
end
