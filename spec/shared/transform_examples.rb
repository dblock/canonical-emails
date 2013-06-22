shared_examples 'transform fixture_examples' do
  yml_examples.each do |example|
    it "transforms '#{example['source']}'" do
      subject.transform(example['source']).tap do |email|
        email.local.should == example['local']
        email.domain.should == example['domain']
        email.name.should == example['name']
      end
    end
  end
end
